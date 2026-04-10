import 'package:hive/hive.dart';

part 'vehicle_model.g.dart';

@HiveType(typeId: 1)
class VehicleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String address; // MAC address or BLE UUID

  @HiveField(3)
  final bool isBle; // true = BLE, false = Classic

  @HiveField(4)
  bool isDefault;

  @HiveField(5)
  final DateTime addedAt;

  @HiveField(6)
  int? rssi; // Signal strength (negative dBm)

  VehicleModel({
    required this.id,
    required this.name,
    required this.address,
    required this.isBle,
    this.isDefault = false,
    required this.addedAt,
    this.rssi,
  });

  String get typeLabel => isBle ? 'BLE' : 'Classic';
  String get shortAddress {
    if (address.length > 8) {
      return '${address.substring(0, 8)}…';
    }
    return address;
  }
}
