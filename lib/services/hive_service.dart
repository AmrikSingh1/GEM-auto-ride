import 'package:hive_flutter/hive_flutter.dart';
import '../core/models/ride_model.dart';
import '../core/models/vehicle_model.dart';

class HiveService {
  static const _ridesBoxName = 'rides';
  static const _vehiclesBoxName = 'vehicles';
  static const _settingsBoxName = 'settings';

  static Box<RideModel> get ridesBox => Hive.box<RideModel>(_ridesBoxName);
  static Box<VehicleModel> get vehiclesBox =>
      Hive.box<VehicleModel>(_vehiclesBoxName);
  static Box get settingsBox => Hive.box(_settingsBoxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(RideModelAdapter());
    Hive.registerAdapter(VehicleModelAdapter());
    await Hive.openBox<RideModel>(_ridesBoxName);
    await Hive.openBox<VehicleModel>(_vehiclesBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  // ── Rides ──────────────────────────────────────────────────────────────────

  static Future<void> saveRide(RideModel ride) async {
    await ridesBox.put(ride.id, ride);
  }

  static Future<void> updateRide(RideModel ride) async {
    await ridesBox.put(ride.id, ride);
  }

  static Future<void> deleteRide(String id) async {
    await ridesBox.delete(id);
  }

  static List<RideModel> getAllRides() {
    final rides = ridesBox.values.toList();
    // Sort newest first
    rides.sort((a, b) => b.startTime.compareTo(a.startTime));
    return rides;
  }

  static RideModel? getRide(String id) => ridesBox.get(id);

  // ── Vehicles ───────────────────────────────────────────────────────────────

  static Future<void> saveVehicle(VehicleModel vehicle) async {
    await vehiclesBox.put(vehicle.id, vehicle);
  }

  static Future<void> deleteVehicle(String id) async {
    await vehiclesBox.delete(id);
  }

  static List<VehicleModel> getAllVehicles() {
    return vehiclesBox.values.toList();
  }

  static VehicleModel? getDefaultVehicle() {
    try {
      return vehiclesBox.values.firstWhere((v) => v.isDefault);
    } catch (_) {
      return vehiclesBox.values.isEmpty ? null : vehiclesBox.values.first;
    }
  }

  static Future<void> setDefaultVehicle(String id) async {
    for (final v in vehiclesBox.values) {
      v.isDefault = v.id == id;
      await v.save();
    }
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  static bool get backgroundEnabled =>
      settingsBox.get('backgroundEnabled', defaultValue: true) as bool;

  static Future<void> setBackgroundEnabled(bool value) async =>
      settingsBox.put('backgroundEnabled', value);

  static int get totalCoins =>
      settingsBox.get('totalCoins', defaultValue: 0) as int;

  static Future<void> addCoins(int amount) async =>
      settingsBox.put('totalCoins', totalCoins + amount);
}
