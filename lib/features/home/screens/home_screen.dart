import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/active_ride_provider.dart';
import '../widgets/save_commute_sheet.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _startPressed = false;
  LatLng? _idlePosition;     // current live position
  LatLng? _pendingPosition;  // held until the map controller is ready
  StreamSubscription<Position>? _positionStream;
  Timer? _recenterTimer;     // auto-follows user every 5s on idle screen

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _checkPermissionsAndTrack();
    // Auto-recenter every 5 seconds when idle
    _recenterTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final pos = _idlePosition;
      if (pos != null &&
          _mapController != null &&
          ref.read(activeRideProvider).phase == RidePhase.idle) {
        _animateCamera(pos);
      }
    });
  }

  Future<void> _checkPermissionsAndTrack() async {
    // ── 1. Ensure GPS radio is ON (prompt to enable if not) ─────────────────
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('GEM: GPS radio is OFF – prompting settings');
      await Geolocator.openLocationSettings();
      await Future.delayed(const Duration(seconds: 2));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
    }

    // ── 2. Check status only — PermissionService already requested in main() ─
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('GEM: Location not granted – cannot track');
      return;
    }

    debugPrint('GEM: Location OK, starting position stream');

    // ── 3. Live position stream ──────────────────────────────────────────────
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() => _idlePosition = newPos);

      if (_mapController == null) {
        _pendingPosition = newPos;
      } else if (ref.read(activeRideProvider).phase == RidePhase.idle) {
        _animateCamera(newPos);
      }
    });
  }

  @override
  void dispose() {
    _recenterTimer?.cancel();
    _positionStream?.cancel();
    _pulseCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Camera follow ─────────────────────────────────────────────────────────

  void _animateCamera(LatLng pos) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pos,
          zoom: 16,
        ),
      ),
    );
  }

  // ── Start ride ────────────────────────────────────────────────────────────

  Future<void> _onStart() async {
    if (_startPressed) return;
    setState(() => _startPressed = true);
    HapticFeedback.heavyImpact();
    await ref.read(activeRideProvider.notifier).start();
    setState(() => _startPressed = false);
  }

  // ── Finish ────────────────────────────────────────────────────────────────

  Future<void> _onFinish(ActiveRideState rideState) async {
    HapticFeedback.heavyImpact();
    // Pause timer while showing sheet
    if (rideState.phase == RidePhase.active) {
      ref.read(activeRideProvider.notifier).pause();
    }
    await showSaveCommuteSheet(context, ref, rideState);
  }

  @override
  Widget build(BuildContext context) {
    final ride = ref.watch(activeRideProvider);

    // Follow user on map
    ref.listen<ActiveRideState>(activeRideProvider, (prev, next) {
      if (next.phase == RidePhase.active &&
          next.currentPosition != null &&
          next.currentPosition != prev?.currentPosition) {
        _animateCamera(next.currentPosition!);
      }
    });

    if (ride.phase == RidePhase.idle) {
      return _buildIdleScreen(context, ride);
    }
    return _buildActiveScreen(context, ride);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // IDLE SCREEN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildIdleScreen(BuildContext context, ActiveRideState ride) {
    return _buildBaseMapUI(
      ride: ride,
      overlays: [
        _buildIdleHeader(),
        _buildIdleBody(ride),
      ],
    );
  }

  Widget _buildIdleHeader() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Auto-Ride Active',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⚡', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text(
                  'My Coins',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleBody(ActiveRideState ride) {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.settings_input_antenna_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getIdleTitle(ride.fsmStateString),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getIdleSubtitle(ride.fsmStateString, ride.currentSpeedKmh),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  String _getIdleTitle(String fsmState) {
    if (fsmState == 'detecting') return 'Detecting Movement...';
    if (fsmState == 'btDetecting') return 'Vehicle Connected...';
    if (fsmState == 'confirming') return 'Confirming Ride...';
    return 'Ready to track your commute';
  }

  String _getIdleSubtitle(String fsmState, double speed) {
    if (fsmState == 'detecting' || fsmState == 'confirming' || fsmState == 'btDetecting') {
      return 'Current speed: ${speed.toStringAsFixed(1)} km/h';
    }
    return 'Waiting for you to start moving...';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIVE / PAUSED SCREEN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildActiveScreen(BuildContext context, ActiveRideState ride) {
    final isPaused = ride.phase == RidePhase.paused;

    return _buildBaseMapUI(
      ride: ride,
      bottomPadding: 180,
      overlays: [
        // ── Paused overlay badge ───────────────────────────────────────────
        if (isPaused)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withOpacity(0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pause_circle_rounded,
                        color: Colors.black, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'PAUSED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Back-to-centre FAB ────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 196,
          child: GestureDetector(
            onTap: () {
              if (ride.currentPosition != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                        target: ride.currentPosition!, zoom: 16),
                  ),
                );
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ),

        // ── Bottom panel ──────────────────────────────────────────────────
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildBottomPanel(ride, isPaused),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMMON MAP BASE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBaseMapUI({
    required ActiveRideState ride,
    required List<Widget> overlays,
    double bottomPadding = 0,
  }) {
    final polylines = <Polyline>{
      if (ride.polylinePoints.length >= 2)
        Polyline(
          polylineId: const PolylineId('route'),
          points: ride.polylinePoints,
          color: AppColors.primary,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
    };

    final markers = <Marker>{
      if (ride.polylinePoints.isNotEmpty)
        Marker(
          markerId: const MarkerId('start'),
          position: ride.polylinePoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      // We rely on myLocationEnabled for the user's blue dot natively instead of drawing a custom marker
    };

    final initialPos = ride.currentPosition ?? _idlePosition ?? const LatLng(28.6139, 77.2090);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: bottomPadding,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPos,
                zoom: 16,
              ),
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              polylines: polylines,
              markers: markers,
              style: _darkMapStyle,
              onMapCreated: (controller) {
                _mapController = controller;
                // Use the real GPS position if we already have one from the stream
                final target = _idlePosition ?? _pendingPosition;
                if (target != null) {
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: target, zoom: 16),
                    ),
                  );
                }
                _pendingPosition = null;
              },
            ),
          ),
          ...overlays,
        ],
      ),
    );
  }

  Widget _buildBottomPanel(ActiveRideState ride, bool isPaused) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle indicator
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 12),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Timer
                _StatDisplay(
                  icon: Icons.timer_rounded,
                  value: ride.formattedTime,
                  label: 'Duration',
                  color: isPaused ? AppColors.warning : AppColors.primary,
                ),
                // Divider
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.divider,
                ),
                // Distance
                _StatDisplay(
                  icon: Icons.straighten_rounded,
                  value: ride.formattedDistance,
                  label: 'Distance',
                  color: AppColors.accent,
                ),
                // Divider
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.divider,
                ),
                // Speed
                _StatDisplay(
                  icon: Icons.speed_rounded,
                  value: '${ride.avgSpeedKmh.toStringAsFixed(0)} km/h',
                  label: 'Avg Speed',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Pause / Resume
                Expanded(
                  child: _ActionButton(
                    label: isPaused ? 'RESUME' : 'PAUSE',
                    icon: isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: isPaused
                        ? AppColors.primary
                        : AppColors.surfaceCard,
                    textColor: isPaused ? Colors.black : AppColors.textSecondary,
                    borderColor:
                        isPaused ? AppColors.primary : AppColors.divider,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (isPaused) {
                        ref.read(activeRideProvider.notifier).resume();
                      } else {
                        ref.read(activeRideProvider.notifier).pause();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Finish
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    label: 'FINISH',
                    icon: Icons.flag_rounded,
                    color: AppColors.ending,
                    textColor: Colors.white,
                    borderColor: AppColors.ending,
                    onPressed: () => _onFinish(
                        ref.read(activeRideProvider)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────



class _StatDisplay extends StatelessWidget {
  const _StatDisplay({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dark Map Style ─────────────────────────────────────────────────────────────

const String? _darkMapStyle = r'''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';
