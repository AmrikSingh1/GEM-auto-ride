import 'dart:async';
import 'dart:io';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart' as ar;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/models/ride_model.dart';
import '../core/models/vehicle_model.dart';
import 'hive_service.dart';
import 'sync_service.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

enum FsmState { idle, detecting, btDetecting, confirming, inProgress, ending }

class BackgroundServiceManager {
  static Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'gem_ride_tracking', // id
      'GEM Ride Tracking', // title
      description: 'Used for monitoring active rides.', // description
      importance: Importance.low, // importance must be at least LOW to show icon
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,           // Restart automatically on device boot
        isForegroundMode: true,    // Keeps service alive even when app is in background
        notificationChannelId: 'gem_ride_tracking',
        initialNotificationTitle: 'GEM – Auto Ride Active',
        initialNotificationContent: 'Monitoring your commute in the background',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: true,     // Survive device restart
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> startService() async {
    await FlutterBackgroundService().startService();
  }

  static Future<void> stopService() async {
    FlutterBackgroundService().invoke('stop');
  }

  static bool get isRunning => true;
}

// ── Background Isolate Entry Point ───────────────────────────────────────────

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  // Init Hive in background isolate
  await Hive.initFlutter();
  Hive.registerAdapter(RideModelAdapter());
  Hive.registerAdapter(VehicleModelAdapter());
  await Hive.openBox<RideModel>('rides');
  await Hive.openBox<VehicleModel>('vehicles');
  await Hive.openBox('settings');

  final isolate = _GemIsolate(service);
  await isolate.run();
}

// ── Isolate Logic ─────────────────────────────────────────────────────────────

class _GemIsolate {
  _GemIsolate(this._service);

  final ServiceInstance _service;
  
  // State
  FsmState _state = FsmState.idle;
  
  // Sensors
  StreamSubscription<ar.ActivityEvent>? _activitySub;
  StreamSubscription<Position>? _gpsStreamSub;
  Timer? _gpsTimer;

  // FSM Counters
  int _detectingTicks = 0; // 15s interval
  int _btDetectingTicks = 0; // 3s interval (for 30s > 5km/h check)
  int _btLowSpeedTicks = 0; // 3s interval (fallback to detecting if traffic is too long)
  int _confirmingTicks = 0; // 3s interval
  int _lowSpeedTicks = 0; // 1s interval (during ride)
  int _endingTicks = 0; // 1s interval

  // Ride Data
  String? _currentRideId;
  final List<Position> _positions = [];

  Future<void> run() async {
    _updateNotification('Monitoring motion...');

    _service.on('stop').listen((_) async {
      await _cleanup();
      _service.stopSelf();
    });

    _service.on('manualStart').listen((_) async {
      if (_state == FsmState.idle) {
        _transitionTo(FsmState.inProgress);
      }
    });

    // Start IDLE state logic directly
    _transitionTo(FsmState.idle);
  }

  // ── State Machine Transitions ───────────────────────────────────────────────

  void _transitionTo(FsmState newState) {
    // print removed
    
    // Exit current state cleanup
    if (_state != newState) {
      if (newState == FsmState.idle) {
        _stopGps();
        _startActivityRecognition();
      } else if (newState == FsmState.detecting) {
        _stopActivityRecognition();
        _startDetectingTimer();
      } else if (newState == FsmState.btDetecting) {
        _stopActivityRecognition();
        _startBtDetectingTimer();
      } else if (newState == FsmState.confirming) {
        _stopGps();
        _startConfirmingTimer();
      } else if (newState == FsmState.inProgress) {
        _stopGps();
        _startRideStream();
        if (_state != FsmState.confirming && _state != FsmState.ending) {
          _beginRideRecord();
        }
      } else if (newState == FsmState.ending) {
        // Keep stream running, just change state logic
      }
    }

    _state = newState;
    _broadcastState();
    _updateNotification('State: ${_state.name.toUpperCase()}');
  }

  // ── Sensor Handlers ─────────────────────────────────────────────────────────

  void _startActivityRecognition() {
    _activitySub?.cancel();
    _activitySub = ar.ActivityRecognition()
        .activityStream(runForegroundService: false)
        .listen((event) async {
      if (event.type == ar.ActivityType.inVehicle ||
          event.type == ar.ActivityType.onBicycle ||
          event.type == ar.ActivityType.running ||
          event.type == ar.ActivityType.walking) {
        // Detected motion, check BT
        final isBtNearby = await _isRegisteredBluetoothNearby();
        if (isBtNearby) {
          _transitionTo(FsmState.btDetecting);
        } else {
          _transitionTo(FsmState.detecting);
        }
      }
    });
  }

  void _stopActivityRecognition() {
    _activitySub?.cancel();
    _activitySub = null;
  }

  void _startDetectingTimer() async {
    _detectingTicks = 0;
    _gpsTimer?.cancel();
    
    final isLow = await _isLowBattery();
    final interval = isLow ? 30 : 15;

    _gpsTimer = Timer.periodic(Duration(seconds: interval), (_) async {
      final pos = await _getLowPowerPosition();
      if (pos == null) return;
      
      final speedKmh = pos.speed * 3.6;
      _broadcastData(speedKmh, pos);

      if (speedKmh > 15.0) {
        _transitionTo(FsmState.confirming);
      } else {
        _detectingTicks++;
        // 3 minutes = 12 ticks of 15s (or 6 ticks of 30s)
        final maxTicks = isLow ? 6 : 12;
        if (_detectingTicks >= maxTicks) {
          _transitionTo(FsmState.idle);
        }
      }
    });
  }

  void _startBtDetectingTimer() {
    _btDetectingTicks = 0;
    _btLowSpeedTicks = 0;
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final pos = await _getHighPowerPosition();
      if (pos == null) return;

      final speedKmh = pos.speed * 3.6;
      _broadcastData(speedKmh, pos);

      // BT Path: speed > 5 km/h for 30s
      if (speedKmh > 5.0) {
        _btDetectingTicks++;
        _btLowSpeedTicks = 0; // reset drop counter if moving again
        if (_btDetectingTicks >= 10) { // 10 ticks = 30 seconds
          _transitionTo(FsmState.inProgress);
        }
      } else {
        // Reset confirming ticks, wait out minor stops
        _btDetectingTicks = 0;
        _btLowSpeedTicks++;
        if (_btLowSpeedTicks >= 40) { // 2 minutes with BT connected but no speed
          _transitionTo(FsmState.detecting); // Fallback if stuck in traffic
        }
      }
    });
  }

  void _startConfirmingTimer() async {
    _confirmingTicks = 0;
    _gpsTimer?.cancel();

    final isLow = await _isLowBattery();
    final interval = isLow ? 6 : 3;

    _gpsTimer = Timer.periodic(Duration(seconds: interval), (_) async {
      final pos = await _getHighPowerPosition();
      if (pos == null) return;

      final speedKmh = pos.speed * 3.6;
      _broadcastData(speedKmh, pos);

      if (speedKmh > 15.0) {
        _confirmingTicks++;
        // 90 seconds = 30 ticks of 3s (or 15 ticks of 6s)
        final maxTicks = isLow ? 15 : 30;
        if (_confirmingTicks >= maxTicks) {
          _transitionTo(FsmState.inProgress);
        }
      } else {
        // Drops below 15 before 90s -> back to detecting
        _transitionTo(FsmState.detecting);
      }
    });
  }

  void _startRideStream() async {
    _lowSpeedTicks = 0;
    _endingTicks = 0;
    _gpsStreamSub?.cancel();

    final isLow = await _isLowBattery();
    final dFilter = isLow ? 5 : 2; // back off distance filter if low batt

    _gpsStreamSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: dFilter,
      ),
    ).listen((pos) async {
      final speedKmh = pos.speed * 3.6;
      _broadcastData(speedKmh, pos);
      _updateNotification('${speedKmh.toStringAsFixed(0)} km/h');

      if (_state == FsmState.inProgress) {
        _positions.add(pos);
        if (speedKmh < 3.0) {
          _lowSpeedTicks++;
          if (_lowSpeedTicks >= 30) { // 30 seconds at < 3km/h
            _transitionTo(FsmState.ending);
          }
        } else {
          _lowSpeedTicks = 0;
        }
      } else if (_state == FsmState.ending) {
        _positions.add(pos);
        if (speedKmh > 3.0) {
          // Speed picked up, back to IN PROGRESS
          _transitionTo(FsmState.inProgress);
        } else {
          _endingTicks++;
          if (_endingTicks >= 180) { // 3 minutes at near-zero
            await _endRideRecord();
            _transitionTo(FsmState.idle);
          }
        }
      }
    });
  }

  void _stopGps() {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    _gpsStreamSub?.cancel();
    _gpsStreamSub = null;
  }

  // ── Ride Database Handlers ──────────────────────────────────────────────────

  Future<void> _beginRideRecord() async {
    _currentRideId = const Uuid().v4();
    _positions.clear();
    final ride = RideModel(
      id: _currentRideId!,
      startTime: DateTime.now(),
      latitudes: [],
      longitudes: [],
    );
    await HiveService.saveRide(ride);
    _service.invoke('rideStarted', {'rideId': _currentRideId});
  }

  Future<void> _endRideRecord() async {
    if (_currentRideId == null) return;
    
    final ride = HiveService.getRide(_currentRideId!);
    if (ride == null) return;

    double totalDist = 0;
    double maxSpeed = 0;
    double totalSpeed = 0;

    for (int i = 0; i < _positions.length; i++) {
      final pos = _positions[i];
      final spd = pos.speed * 3.6;
      if (spd > maxSpeed) maxSpeed = spd;
      totalSpeed += spd;

      if (i > 0) {
        totalDist += Geolocator.distanceBetween(
          _positions[i - 1].latitude,
          _positions[i - 1].longitude,
          pos.latitude,
          pos.longitude,
        );
      }
      ride.latitudes.add(pos.latitude);
      ride.longitudes.add(pos.longitude);
    }

    ride.endTime = DateTime.now();
    ride.distanceKm = totalDist / 1000;
    ride.maxSpeedKmh = maxSpeed;
    ride.avgSpeedKmh = _positions.isEmpty ? 0 : totalSpeed / _positions.length;
    ride.coinsEarned = (ride.distanceKm * 10).round();
    ride.title = 'Auto-detected Commute';

    await HiveService.updateRide(ride);
    await HiveService.addCoins(ride.coinsEarned);

    _service.invoke('rideEnded', {'rideId': _currentRideId});
    _currentRideId = null;
    _positions.clear();

    // Trigger Backend Sync via Workmanager
    SyncService.enqueueSync();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<bool> _isLowBattery() async {
    try {
      final level = await Battery().batteryLevel;
      return level <= 15;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isRegisteredBluetoothNearby() async {
    final vehicles = HiveService.getAllVehicles();
    if (vehicles.isEmpty) return false;

    // Check Classic Bluetooth connections (Android only)
    if (Platform.isAndroid) {
      try {
        final bonded = await fbs.FlutterBluetoothSerial.instance.getBondedDevices();
        for (final d in bonded) {
          if (d.isConnected && vehicles.any((v) => !v.isBle && v.address == d.address)) {
            return true;
          }
        }
      } catch (_) {}
    }

    // Check BLE devices
    final bleVehicles = vehicles.where((v) => v.isBle).toList();
    if (bleVehicles.isNotEmpty) {
      try {
        final connected = fbp.FlutterBluePlus.connectedDevices;
        if (connected.any((d) => bleVehicles.any((v) => v.address == d.remoteId.str))) {
          return true;
        }
        
        bool found = false;
        final sub = fbp.FlutterBluePlus.scanResults.listen((results) {
          for (final r in results) {
            if (bleVehicles.any((v) => v.address == r.device.remoteId.str)) {
              found = true;
              break;
            }
          }
        });
        await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
        await sub.cancel();
        if (found) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<Position?> _getLowPowerPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Position?> _getHighPowerPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }

  void _broadcastState() {
    _service.invoke('updateState', {'state': _state.name});
  }

  void _broadcastData(double speedKmh, Position pos) {
    _service.invoke('update', {
      'speed': speedKmh,
      'lat': pos.latitude,
      'lng': pos.longitude,
      'state': _state.name,
    });
  }

  void _updateNotification(String content) {
    if (_service is AndroidServiceInstance) {
      _service.setForegroundNotificationInfo(
          title: 'GEM',
          content: content,
        );
    }
  }

  Future<void> _cleanup() async {
    _stopActivityRecognition();
    _stopGps();
    if (_state == FsmState.inProgress || _state == FsmState.ending) {
      await _endRideRecord();
    }
  }
}
