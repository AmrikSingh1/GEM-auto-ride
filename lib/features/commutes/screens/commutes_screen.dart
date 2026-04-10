import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bento_card.dart';
import '../providers/commutes_provider.dart';
import 'ride_detail_screen.dart';

class CommutesScreen extends ConsumerWidget {
  const CommutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rides = ref.watch(commutesProvider);
    final stats = ref.watch(totalStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(stats)),
            rides.isEmpty
                ? const SliverFillRemaining(child: _EmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ride = rides[index];
                        return BentoCard(
                          ride: ride,
                          index: index,
                          onTap: () {
                            Navigator.push(
                              context,
                              _slideRoute(RideDetailScreen(rideId: ride.id)),
                            );
                          },
                        );
                      },
                      childCount: rides.length,
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      ({int coins, int count, double km}) stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Commutes',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Stats row bento grid
          Row(
            children: [
              _StatBento(
                value: '${stats.km.toStringAsFixed(1)}',
                unit: 'km',
                label: 'Total Distance',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _StatBento(
                value: '${stats.coins}',
                unit: '⚡',
                label: 'Total Coins',
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              _StatBento(
                value: '${stats.count}',
                unit: '',
                label: 'Total Rides',
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
        ],
      ),
    );
  }

  Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

class _StatBento extends StatelessWidget {
  const _StatBento({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  final String value;
  final String unit;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Rides Yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first ride from the\nHome screen to see it here.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
