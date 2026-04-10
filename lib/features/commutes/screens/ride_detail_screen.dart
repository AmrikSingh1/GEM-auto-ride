import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/commutes_provider.dart';
import '../../../core/models/ride_model.dart';

class RideDetailScreen extends ConsumerWidget {
  const RideDetailScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(rideDetailProvider(rideId));

    if (ride == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Text('Ride not found',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Ride Detail',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── Top 40%: Google Map ──────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.60,
            child: _RideMap(ride: ride),
          ),

          // ── Bottom 60%: Slide-up panel ───────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _RideAnalyticsPanel(ride: ride),
          ),
        ],
      ),
    );
  }
}

// ── Map Widget ──────────────────────────────────────────────────────────────

class _RideMap extends StatefulWidget {
  const _RideMap({required this.ride});
  final RideModel ride;

  @override
  State<_RideMap> createState() => _RideMapState();
}

class _RideMapState extends State<_RideMap> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildPolylines();
  }

  void _buildPolylines() {
    final lats = widget.ride.latitudes;
    final lngs = widget.ride.longitudes;

    if (lats.isEmpty) return;

    final points = List.generate(
        lats.length, (i) => LatLng(lats[i], lngs[i]));

    _polylines = {
      Polyline(
        polylineId: const PolylineId('ride_path'),
        points: points,
        color: AppColors.primary,
        width: 5,
        patterns: [],
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };

    if (points.isNotEmpty) {
      _markers = {
        Marker(
          markerId: const MarkerId('start'),
          position: points.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
        if (points.length > 1)
          Marker(
            markerId: const MarkerId('end'),
            position: points.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'End'),
          ),
      };
    }
  }

  LatLngBounds? _getBounds() {
    final lats = widget.ride.latitudes;
    final lngs = widget.ride.longitudes;
    if (lats.isEmpty) return null;

    double minLat = lats.first, maxLat = lats.first;
    double minLng = lngs.first, maxLng = lngs.first;

    for (int i = 0; i < lats.length; i++) {
      if (lats[i] < minLat) minLat = lats[i];
      if (lats[i] > maxLat) maxLat = lats[i];
      if (lngs[i] < minLng) minLng = lngs[i];
      if (lngs[i] > maxLng) maxLng = lngs[i];
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lats = widget.ride.latitudes;
    final center = lats.isNotEmpty
        ? LatLng(lats[lats.length ~/ 2], widget.ride.longitudes[lats.length ~/ 2])
        : const LatLng(28.6139, 77.2090); // Default: New Delhi

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 14),
      mapType: MapType.normal,
      polylines: _polylines,
      markers: _markers,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      style: _darkMapStyle,
      onMapCreated: (controller) {
        _mapController = controller;
        final bounds = _getBounds();
        if (bounds != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 60),
            );
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// ── Analytics Panel ──────────────────────────────────────────────────────────

class _RideAnalyticsPanel extends StatelessWidget {
  const _RideAnalyticsPanel({required this.ride});
  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      minChildSize: 0.35,
      maxChildSize: 0.90,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title + Coins
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ride.title?.isNotEmpty == true)
                        Text(
                          ride.title!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      Text(
                        _formatDate(ride.startTime),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: ride.title?.isNotEmpty == true ? 13 : 20,
                          fontWeight: ride.title?.isNotEmpty == true
                              ? FontWeight.w400
                              : FontWeight.w700,
                          color: ride.title?.isNotEmpty == true
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        ride.vehicleName ?? 'Manual Ride',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFAB00), Color(0xFFFF6D00)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          '+${ride.coinsEarned}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Metric grid (2 × 2 Bento)
              _MetricGrid(ride: ride),

              const SizedBox(height: 24),

              // Speed chart placeholder / bar
              _SpeedBar(
                  avgSpeed: ride.avgSpeedKmh, maxSpeed: ride.maxSpeedKmh),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$m $amPm';
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.ride});
  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _MetricBento(
          icon: Icons.straighten_rounded,
          label: 'Distance',
          value: ride.formattedDistance,
          color: AppColors.primary,
        ),
        _MetricBento(
          icon: Icons.timer_rounded,
          label: 'Duration',
          value: ride.formattedDuration,
          color: AppColors.accent,
        ),
        _MetricBento(
          icon: Icons.speed_rounded,
          label: 'Top Speed',
          value: '${ride.maxSpeedKmh.toStringAsFixed(0)} km/h',
          color: AppColors.warning,
        ),
        _MetricBento(
          icon: Icons.bar_chart_rounded,
          label: 'Avg Speed',
          value: '${ride.avgSpeedKmh.toStringAsFixed(0)} km/h',
          color: AppColors.accent,
        ),
      ],
    );
  }
}

class _MetricBento extends StatelessWidget {
  const _MetricBento({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedBar extends StatelessWidget {
  const _SpeedBar({required this.avgSpeed, required this.maxSpeed});
  final double avgSpeed;
  final double maxSpeed;

  @override
  Widget build(BuildContext context) {
    final pct = maxSpeed > 0 ? (avgSpeed / maxSpeed).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Speed Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: 1,
            alignment: Alignment.centerLeft,
            child: LayoutBuilder(
              builder: (_, constraints) {
                return Stack(
                  children: [
                    // Max speed bar (full width)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Avg speed bar
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avg ${avgSpeed.toStringAsFixed(0)} km/h',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.primary),
            ),
            Text(
              'Max ${maxSpeed.toStringAsFixed(0)} km/h',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.warning),
            ),
          ],
        ),
      ],
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
