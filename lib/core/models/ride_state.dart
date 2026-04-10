import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Sealed class representing the GEM ride state machine.
/// Transitions: Idle -> Detecting -> Confirming -> InProgress -> Ending -> Idle
sealed class RideState {
  const RideState();

  String get label;
  Color get color;
  String get description;
  bool get isActive;
}

final class IdleState extends RideState {
  const IdleState();

  @override
  String get label => 'IDLE';

  @override
  Color get color => AppColors.idle;

  @override
  String get description => 'Waiting to detect a ride...';

  @override
  bool get isActive => false;
}

final class DetectingState extends RideState {
  const DetectingState();

  @override
  String get label => 'DETECTING';

  @override
  Color get color => AppColors.detecting;

  @override
  String get description => 'Looking for motion & Bluetooth...';

  @override
  bool get isActive => true;
}

final class ConfirmingState extends RideState {
  const ConfirmingState();

  @override
  String get label => 'CONFIRMING';

  @override
  Color get color => AppColors.confirming;

  @override
  String get description => 'Motion detected — confirming ride start...';

  @override
  bool get isActive => true;
}

final class InProgressState extends RideState {
  const InProgressState({this.rideId});

  final String? rideId;

  @override
  String get label => 'IN RIDE';

  @override
  Color get color => AppColors.inProgress;

  @override
  String get description => 'Ride is active and being tracked.';

  @override
  bool get isActive => true;
}

final class EndingState extends RideState {
  const EndingState();

  @override
  String get label => 'ENDING';

  @override
  Color get color => AppColors.ending;

  @override
  String get description => 'Finalizing ride data...';

  @override
  bool get isActive => true;
}
