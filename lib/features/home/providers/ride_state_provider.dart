import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../../core/models/ride_state.dart';

// ── Ride State Provider ────────────────────────────────────────────────────────

class RideStateNotifier extends Notifier<RideState> {
  StreamSubscription? _stateSubscription;

  @override
  RideState build() {
    _listenToService();
    ref.onDispose(() => _stateSubscription?.cancel());
    return const IdleState();
  }

  void _listenToService() {
    final service = FlutterBackgroundService();

    _stateSubscription = service.on('update').listen((data) {
      if (data == null) return;
      final stateStr = data['state'] as String?;
      switch (stateStr) {
        case 'idle':
          state = const IdleState();
          break;
        case 'confirming':
          state = const ConfirmingState();
          break;
        case 'inProgress':
          state = InProgressState(rideId: data['rideId'] as String?);
          break;
        case 'ending':
          state = const EndingState();
          break;
        default:
          state = const DetectingState();
      }
    });

    service.on('rideStarted').listen((data) {
      state = InProgressState(rideId: data?['rideId'] as String?);
    });

    service.on('rideEnded').listen((_) {
      state = const IdleState();
    });
  }

  void startManual() {
    state = const DetectingState();
    FlutterBackgroundService().invoke('manualStart');
  }

  void stop() {
    state = const EndingState();
    FlutterBackgroundService().invoke('stop');
  }
}

final rideStateProvider = NotifierProvider<RideStateNotifier, RideState>(
  RideStateNotifier.new,
);

// ── Speed Provider ─────────────────────────────────────────────────────────────

class SpeedNotifier extends Notifier<double> {
  StreamSubscription? _sub;

  @override
  double build() {
    _listenToService();
    ref.onDispose(() => _sub?.cancel());
    return 0.0;
  }

  void _listenToService() {
    final service = FlutterBackgroundService();
    _sub = service.on('update').listen((data) {
      if (data == null) return;
      final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;
      state = speed;
    });
  }
}

final speedProvider = NotifierProvider<SpeedNotifier, double>(
  SpeedNotifier.new,
);

// ── Current Ride ID Provider ───────────────────────────────────────────────────

final currentRideIdProvider = Provider<String?>((ref) {
  final state = ref.watch(rideStateProvider);
  return state is InProgressState ? state.rideId : null;
});
