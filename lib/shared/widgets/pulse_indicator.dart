import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/ride_state.dart';
import '../../core/theme/app_colors.dart';

/// Animated flowing gradient orb that represents the current ride state.
/// The orb pulses and changes color based on [rideState].
class PulseIndicator extends StatefulWidget {
  const PulseIndicator({super.key, required this.rideState});

  final RideState rideState;

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  Color get _stateColor => widget.rideState.color;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  bool get _shouldPulse => widget.rideState.isActive;

  @override
  Widget build(BuildContext context) {
    if (_shouldPulse) {
      _pulseController.repeat(reverse: true);
      _rotateController.repeat();
    } else {
      _pulseController.stop();
      _rotateController.stop();
    }

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ripple rings (shown when active)
          if (_shouldPulse) ...[
            _RippleRing(color: _stateColor, delay: 0),
            _RippleRing(color: _stateColor, delay: 600),
            _RippleRing(color: _stateColor, delay: 1200),
          ],

          // Core animated orb
          AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _rotateController]),
            builder: (_, __) {
              return Transform.scale(
                scale: _shouldPulse ? _pulseAnimation.value : 1.0,
                child: Opacity(
                  opacity: _shouldPulse ? _opacityAnimation.value : 0.8,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          _stateColor.withOpacity(0.9),
                          _stateColor.withOpacity(0.3),
                          AppColors.surface.withOpacity(0.5),
                          _stateColor.withOpacity(0.9),
                        ],
                        transform: GradientRotation(_rotateController.value * 2 * pi),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _stateColor.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface.withOpacity(0.85),
                          border: Border.all(
                            color: _stateColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // State label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              widget.rideState.label,
              key: ValueKey(widget.rideState.label),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _stateColor,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RippleRing extends StatefulWidget {
  const _RippleRing({required this.color, required this.delay});
  final Color color;
  final int delay;

  @override
  State<_RippleRing> createState() => _RippleRingState();
}

class _RippleRingState extends State<_RippleRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color,
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
