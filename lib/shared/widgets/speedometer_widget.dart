import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Digital speedometer display showing km/h with an animated tween.
class SpeedometerWidget extends StatefulWidget {
  const SpeedometerWidget({super.key, required this.speedKmh});

  final double speedKmh;

  @override
  State<SpeedometerWidget> createState() => _SpeedometerWidgetState();
}

class _SpeedometerWidgetState extends State<SpeedometerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _speedAnimation;
  double _prevSpeed = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _speedAnimation = Tween<double>(begin: 0, end: widget.speedKmh).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SpeedometerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speedKmh != widget.speedKmh) {
      _prevSpeed = _speedAnimation.value;
      _speedAnimation = Tween<double>(
        begin: _prevSpeed,
        end: widget.speedKmh,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _speedAnimation,
      builder: (_, __) {
        final speed = _speedAnimation.value;
        final isMoving = speed > 5;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speed number
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow behind number when at speed
                if (isMoving)
                  Container(
                    width: 220,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 96,
                    fontWeight: FontWeight.w700,
                    color: isMoving ? AppColors.primary : AppColors.textPrimary,
                    letterSpacing: -4,
                    height: 1,
                    shadows: isMoving
                        ? [
                            Shadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 20,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(speed.toStringAsFixed(0)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Unit label
            Text(
              'KM/H',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isMoving
                    ? AppColors.primary.withOpacity(0.8)
                    : AppColors.textMuted,
                letterSpacing: 3,
              ),
            ),
          ],
        );
      },
    );
  }
}
