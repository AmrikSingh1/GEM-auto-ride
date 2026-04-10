import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;
import 'package:geolocator/geolocator.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../services/hive_service.dart';

// Unified Class for both BLE and Classic devices
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.name,
    required this.address,
    required this.isBle,
    this.rssi,
  });

  final String name;
  final String address;
  final bool isBle;
  final int? rssi;
}

// ── Scan Results Provider ──────────────────────────────────────────────────────

class BluetoothScanNotifier extends AsyncNotifier<List<DiscoveredDevice>> {
  StreamSubscription? _bleSub;
  StreamSubscription? _classicSub;

  @override
  Future<List<DiscoveredDevice>> build() async {
    ref.onDispose(() {
      _bleSub?.cancel();
      _classicSub?.cancel();
      fbp.FlutterBluePlus.stopScan();
    });
    return [];
  }

  Future<void> startScan() async {
    state = const AsyncLoading();
    
    // Unified list of devices
    final Map<String, DiscoveredDevice> devicesMap = {};

    try {
      // 1. Check if Bluetooth is ON
      final btState = await fbp.FlutterBluePlus.adapterState.first;
      if (btState != fbp.BluetoothAdapterState.on) {
        if (Platform.isAndroid) {
          await fbp.FlutterBluePlus.turnOn();
        } else {
          throw Exception('Please turn on Bluetooth in Settings to scan devices.');
        }
      }

      // 2. Location Services (Android requirement)
      if (Platform.isAndroid) {
        final locationEnabled = await Geolocator.isLocationServiceEnabled();
        if (!locationEnabled) {
          throw Exception('Location Services must be turned on to scan for Bluetooth devices on Android.');
        }
      }

      // 3. Scan Classic Bluetooth paired devices (Android only)
      if (Platform.isAndroid) {
        try {
          final bondedDevices = await fbs.FlutterBluetoothSerial.instance.getBondedDevices();
          for (final d in bondedDevices) {
            final name = (d.name == null || d.name!.isEmpty) ? 'Unknown Device' : d.name!;
            devicesMap[d.address] = DiscoveredDevice(
              name: name,
              address: d.address,
              isBle: false,
            );
          }
          
          // Optionally listen to classic active discovery (though bonded is usually enough for car stereos)
          _classicSub?.cancel();
          _classicSub = fbs.FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
            if (r.device.name != null && r.device.name!.isNotEmpty) {
               devicesMap[r.device.address] = DiscoveredDevice(
                 name: r.device.name!,
                 address: r.device.address,
                 isBle: false,
                 rssi: r.rssi,
               );
               state = AsyncData(devicesMap.values.toList());
            }
          });
        } catch (e) {
          print('Classic BT Scan failed: $e');
        }
      }

      // 4. Scan BLE devices
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      _bleSub?.cancel();
      _bleSub = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName.isEmpty ? 'Unknown BLE Device' : r.device.platformName;
          final addr = r.device.remoteId.str;
          devicesMap[addr] = DiscoveredDevice(
            name: name,
            address: addr,
            isBle: true,
            rssi: r.rssi,
          );
        }
        state = AsyncData(devicesMap.values.toList());
      });

      // Initial publish of bonded classic devices
      state = AsyncData(devicesMap.values.toList());

    } catch (e) {
      String errorStr = e.toString();
      if (errorStr.contains('Location services are required')) {
        errorStr = 'Location Services must be turned on in Android settings to scan for devices.';
      } else if (errorStr.contains('PlatformException') || errorStr.contains('FlutterBluePlusException')) {
        errorStr = errorStr.split(')').last.trim();
        if (errorStr.isEmpty) errorStr = 'Bluetooth scan failed. Ensure permissions are granted.';
      } else {
        errorStr = errorStr.replaceFirst('Exception: ', '');
      }
      state = AsyncError(errorStr, StackTrace.current);
    }
  }

  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
    _bleSub?.cancel();
    _classicSub?.cancel();
  }
}

final bluetoothScanProvider = AsyncNotifierProvider<BluetoothScanNotifier, List<DiscoveredDevice>>(
  BluetoothScanNotifier.new,
);

// ── Paired Vehicles Provider ───────────────────────────────────────────────────

class VehiclesNotifier extends Notifier<List<VehicleModel>> {
  @override
  List<VehicleModel> build() {
    return HiveService.getAllVehicles();
  }

  void refresh() {
    state = HiveService.getAllVehicles();
  }

  Future<void> addVehicle(VehicleModel vehicle) async {
    await HiveService.saveVehicle(vehicle);
    refresh();
  }

  Future<void> removeVehicle(String id) async {
    await HiveService.deleteVehicle(id);
    refresh();
  }

  Future<void> setDefault(String id) async {
    await HiveService.setDefaultVehicle(id);
    refresh();
  }
}

final vehiclesProvider = NotifierProvider<VehiclesNotifier, List<VehicleModel>>(
  VehiclesNotifier.new,
);

// ── Adapter State Provider ─────────────────────────────────────────────────────

final btAdapterStateProvider = StreamProvider<fbp.BluetoothAdapterState>((ref) {
  return fbp.FlutterBluePlus.adapterState;
});
