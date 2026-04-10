import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../core/models/ride_model.dart';
import 'hive_service.dart';

const String syncRidesTaskName = "sync_rides_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == syncRidesTaskName) {
        await SyncService.syncPendingRides();
      }
      return Future.value(true);
    } catch (err) {
      debugPrint('Sync failed: $err');
      return Future.value(false); // Retries based on constraints
    }
  });
}

class SyncService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  static void enqueueSync() {
    Workmanager().registerOneOffTask(
      "1",
      syncRidesTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected, // Only sync when online
      ),
      initialDelay: const Duration(seconds: 10),
    );
  }

  static Future<void> syncPendingRides() async {
    // 1. Initialize Hive if this is spinning up from a completely dead background state
    await HiveService.init();

    // 2. Crash Recovery Pass (Week 7)
    // Find any rides where the app died before FsmState could call _endRideRecord()
    final allRides = HiveService.getAllRides();
    final crashedRides = allRides.where((r) => r.endTime == null).toList();
    for (final crashed in crashedRides) {
      if (crashed.distanceKm == 0.0 || crashed.latitudes.isEmpty) {
        // App crashed before any distance was logged, or we couldn't save incremental points.
        debugPrint('Purging invalid crashed ride: ${crashed.id}');
        await HiveService.deleteRide(crashed.id);
      } else {
        // Close out the ride as best as we can
        crashed.endTime = DateTime.now();
        crashed.title = 'Recovered Commute';
        await HiveService.updateRide(crashed);
      }
    }

    // 3. Fetch Un-synced
    // Re-fetch since we just modified the DB
    final updatedRides = HiveService.getAllRides();
    final pendingRides = updatedRides.where((r) => r.isSynced == false && r.endTime != null).toList();

    if (pendingRides.isEmpty) {
      debugPrint('No pending rides to sync.');
      return;
    }

    // 4. Mock API Upload & Anti-Cheat Validation
    debugPrint('Found ${pendingRides.length} pending rides. Syncing...');
    
    for (final ride in pendingRides) {
      final result = await _mockApiUpload(ride);
      if (result == 'success') {
         ride.isSynced = true;
         await HiveService.updateRide(ride);
         debugPrint('Ride ${ride.id} synced successfully.');
      } else if (result == 'invalid') {
         ride.isSynced = true;
         await HiveService.updateRide(ride);
      }
    }
  }

  static Future<String> _mockApiUpload(RideModel ride) async {
    // Basic Anti-Cheat checks
    if (ride.distanceKm < 0.1 || ride.avgSpeedKmh > 180.0 || ride.latitudes.length < 5) {
      debugPrint('Ride ${ride.id} failed anti-cheat validation. Discarding sync.');
      // Returning 'invalid' so it marks as synced and doesn't retry submitting invalid data
      return 'invalid'; 
    }

    // Simulate Network Delay
    await Future.delayed(const Duration(seconds: 2));

    // Success
    return 'success';
  }
}
