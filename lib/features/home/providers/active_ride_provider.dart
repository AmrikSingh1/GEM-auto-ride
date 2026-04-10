import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/hive_service.dart';

enum RidePhase { idle, active, paused }

class ActiveRideState {
  const ActiveRideState({
    this.phase = RidePhase.idle,
    this.fsmStateString = 'idle',
    this.elapsedSeconds = 0,
    this.distanceKm = 0.0,
    this.currentPosition,
    this.polylinePoints = const [],
    this.startTime,
    this.rideId,
    this.maxSpeedKmh = 0.0,
    this.currentSpeedKmh = 0.0,
  });

  final RidePhase phase;
  final String fsmStateString;
  final int elapsedSeconds;
  final double distanceKm;
  final LatLng? currentPosition;
  final List<LatLng> polylinePoints;
  final DateTime? startTime;
  final String? rideId;

  final double maxSpeedKmh;
  final double currentSpeedKmh;

  double get avgSpeedKmh => distanceKm > 0 && elapsedSeconds > 0 
      ? (distanceKm / (elapsedSeconds / 3600)) 
      : 0.0;

  String get formattedTime {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedDistance {
    if (distanceKm < 1.0) return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  ActiveRideState copyWith({
    RidePhase? phase,
    String? fsmStateString,
    int? elapsedSeconds,
    double? distanceKm,
    LatLng? currentPosition,
    List<LatLng>? polylinePoints,
    DateTime? startTime,
    String? rideId,
    double? maxSpeedKmh,
    double? currentSpeedKmh,
  }) {
    return ActiveRideState(
      phase: phase ?? this.phase,
      fsmStateString: fsmStateString ?? this.fsmStateString,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      currentPosition: currentPosition ?? this.currentPosition,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      startTime: startTime ?? this.startTime,
      rideId: rideId ?? this.rideId,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
    );
  }
}

class ActiveRideNotifier extends Notifier<ActiveRideState> {
  Timer? _timer;
  StreamSubscription? _serviceSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _startedSub;
  StreamSubscription? _endedSub;

  @override
  ActiveRideState build() {
    ref.onDispose(_cleanup);
    _listenToService();
    return const ActiveRideState();
  }

  void _listenToService() {
    final service = FlutterBackgroundService();

    _stateSub = service.on('updateState').listen((data) {
      if (data == null) return;
      final stateStr = data['state'] as String? ?? 'idle';
      
      RidePhase nextPhase = state.phase;
      if (stateStr == 'inProgress' || stateStr == 'ending' || stateStr == 'paused') {
        nextPhase = stateStr == 'paused' ? RidePhase.paused : RidePhase.active;
      } else if (stateStr == 'idle' || stateStr == 'detecting' || stateStr == 'btDetecting' || stateStr == 'confirming') {
        nextPhase = RidePhase.idle;
      }

      state = state.copyWith(
        phase: nextPhase,
        fsmStateString: stateStr,
      );
    });

    _serviceSub = service.on('update').listen((data) {
      if (data == null) return;
      
      final stateStr = data['state'] as String? ?? state.fsmStateString;
      final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
      final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
      final speedKmh = (data['speed'] as num?)?.toDouble() ?? 0.0;

      final newPoint = LatLng(lat, lng);
      
      RidePhase nextPhase = state.phase;
      if (stateStr == 'inProgress' || stateStr == 'ending' || stateStr == 'paused') {
        nextPhase = stateStr == 'paused' ? RidePhase.paused : RidePhase.active;
      } else {
        nextPhase = RidePhase.idle;
      }

      double addedDist = 0.0;
      List<LatLng> newPoints = List.from(state.polylinePoints);

      if (nextPhase == RidePhase.active && state.currentPosition != null) {
        addedDist = Geolocator.distanceBetween(
          state.currentPosition!.latitude,
          state.currentPosition!.longitude,
          lat,
          lng,
        ) / 1000.0;
        
        // Add point to polyline array
        newPoints.add(newPoint);
      }

      state = state.copyWith(
        phase: nextPhase,
        fsmStateString: stateStr,
        currentPosition: newPoint,
        polylinePoints: newPoints,
        distanceKm: state.distanceKm + addedDist,
        maxSpeedKmh: speedKmh > state.maxSpeedKmh ? speedKmh : state.maxSpeedKmh,
        currentSpeedKmh: speedKmh,
      );
    });

    _startedSub = service.on('rideStarted').listen((data) {
      state = ActiveRideState(
        phase: RidePhase.active,
        fsmStateString: 'inProgress',
        startTime: DateTime.now(),
        rideId: data?['rideId'] as String?,
        currentPosition: state.currentPosition,
        polylinePoints: state.currentPosition != null ? [state.currentPosition!] : [],
      );
      _startTimer();
    });

    _endedSub = service.on('rideEnded').listen((_) {
      _timer?.cancel();
      state = const ActiveRideState();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase == RidePhase.active) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  // Fallback Manual Actions: Passed straight to FSM isolate
  Future<void> start() async {
    // Instantly update UI for immediate feedback
    state = ActiveRideState(
      phase: RidePhase.active,
      fsmStateString: 'inProgress',
      startTime: DateTime.now(),
      currentPosition: state.currentPosition,
      polylinePoints: state.currentPosition != null ? [state.currentPosition!] : [],
    );
    _startTimer();
    
    // Ping background service to officially begin tracking route
    FlutterBackgroundService().invoke('manualStart');
  }

  void pause() {
    // Unsupported natively by pure GPS FSM, but we can mock it here for UI consistency
    state = state.copyWith(phase: RidePhase.paused);
  }

  void resume() {
    state = state.copyWith(phase: RidePhase.active);
  }

  Future<void> finish({required String title}) async {
    FlutterBackgroundService().invoke('stop');
    
    // If the background service stopped tracking but we have a title to save, let's update it in Hive
    final currentId = state.rideId;
    if (currentId != null && title.isNotEmpty) {
      // Small delay to let the core service save its version first via standard cleanup
      Future.delayed(const Duration(seconds: 1), () async {
        final ride = HiveService.getRide(currentId);
        if (ride != null) {
          ride.title = title;
          await HiveService.updateRide(ride);
        }
      });
    }
  }

  Future<void> discard() async {
    final currentId = state.rideId;
    FlutterBackgroundService().invoke('stop');
    
    if (currentId != null) {
      Future.delayed(const Duration(seconds: 1), () async {
        await HiveService.deleteRide(currentId);
      });
    }
  }

  void _cleanup() {
    _timer?.cancel();
    _serviceSub?.cancel();
    _stateSub?.cancel();
    _startedSub?.cancel();
    _endedSub?.cancel();
  }
}

final activeRideProvider = NotifierProvider<ActiveRideNotifier, ActiveRideState>(
  ActiveRideNotifier.new,
);
