import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ride_model.dart';
import '../../../services/hive_service.dart';

class CommutesNotifier extends Notifier<List<RideModel>> {
  @override
  List<RideModel> build() => HiveService.getAllRides();

  void refresh() => state = HiveService.getAllRides();

  Future<void> deleteRide(String id) async {
    await HiveService.deleteRide(id);
    refresh();
  }
}

final commutesProvider =
    NotifierProvider<CommutesNotifier, List<RideModel>>(CommutesNotifier.new);

// Single ride detail provider
final rideDetailProvider = Provider.family<RideModel?, String>((ref, id) {
  return HiveService.getRide(id);
});

// Total stats
final totalStatsProvider = Provider((ref) {
  final rides = ref.watch(commutesProvider);
  double totalKm = 0;
  int totalCoins = 0;
  for (final r in rides) {
    totalKm += r.distanceKm;
    totalCoins += r.coinsEarned;
  }
  return (km: totalKm, coins: totalCoins, count: rides.length);
});
