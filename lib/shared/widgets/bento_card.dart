import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/ride_model.dart';
import '../../core/theme/app_colors.dart';

/// A "Bento Card" showing commute history summary.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.ride,
    required this.onTap,
    this.index = 0,
  });

  final RideModel ride;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEE, MMM d').format(ride.startTime);
    final timeStr = DateFormat('h:mm a').format(ride.startTime);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: title + coins badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.title?.isNotEmpty == true
                              ? ride.title!
                              : 'Commute',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateStr · $timeStr',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Coins Badge
                  _CoinsBadge(coins: ride.coinsEarned),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _StatCell(
                    label: 'DISTANCE',
                    value: ride.formattedDistance,
                    icon: Icons.straighten_rounded,
                    color: AppColors.primary,
                  ),
                  _StatDivider(),
                  _StatCell(
                    label: 'DURATION',
                    value: ride.formattedDuration,
                    icon: Icons.timer_rounded,
                    color: AppColors.accent,
                  ),
                  _StatDivider(),
                  _StatCell(
                    label: 'TOP SPEED',
                    value: '${ride.maxSpeedKmh.toStringAsFixed(0)} km/h',
                    icon: Icons.speed_rounded,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinsBadge extends StatelessWidget {
  const _CoinsBadge({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFAB00), Color(0xFFFF6D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '+$coins',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
