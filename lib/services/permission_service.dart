import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all permissions needed by GEM.
  /// Returns true if all critical permissions are granted.
  static Future<bool> requestAll() async {
    // Step 1: Foreground Location (required first on Android 11+)
    final locationStatus = await Permission.location.request();
    if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
      return false;
    }

    // Step 2: Background / Always-On location (separate dialog on Android 10+)
    await Permission.locationAlways.request();

    // Step 3: Physical Activity Recognition (separate dialog required)
    await Permission.activityRecognition.request();

    // Step 4: Bluetooth
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();

    // Step 5: Notifications (Android 13+)
    await Permission.notification.request();

    // Step 6: Battery optimization exemption — essential for background survival on MIUI/OEM Androids
    await requestBatteryOptimizationExemption();

    return locationStatus.isGranted;
  }

  /// Checks if the app is excluded from battery optimization.
  /// If not, opens the system dialog to request exemption.
  static Future<void> requestBatteryOptimizationExemption() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  /// Returns true if battery optimization is disabled (exempted) for this app.
  static Future<bool> hasBatteryOptimizationExemption() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  static Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<bool> hasBackgroundLocationPermission() async {
    final status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  static Future<bool> hasBluetoothPermission() async {
    final scan = await Permission.bluetoothScan.status;
    final connect = await Permission.bluetoothConnect.status;
    return scan.isGranted && connect.isGranted;
  }

  static Future<void> openSettings() => openAppSettings();
}
