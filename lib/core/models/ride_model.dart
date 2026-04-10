import 'package:hive/hive.dart';

part 'ride_model.g.dart';

@HiveType(typeId: 0)
class RideModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  DateTime? endTime;

  @HiveField(3)
  final List<double> latitudes;

  @HiveField(4)
  final List<double> longitudes;

  @HiveField(5)
  double distanceKm;

  @HiveField(6)
  double maxSpeedKmh;

  @HiveField(7)
  double avgSpeedKmh;

  @HiveField(8)
  int coinsEarned;

  @HiveField(9)
  String? vehicleName;

  @HiveField(10)
  String? title;

  @HiveField(11)
  bool isSynced;

  RideModel({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.latitudes,
    required this.longitudes,
    this.distanceKm = 0.0,
    this.maxSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.coinsEarned = 0,
    this.vehicleName,
    this.title,
    this.isSynced = false,
  });

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);

  String get formattedDuration {
    final d = duration;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
}
