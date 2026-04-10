import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/vehicles/screens/vehicles_screen.dart';
import '../../features/commutes/screens/commutes_screen.dart';

class GemShell extends StatefulWidget {
  const GemShell({super.key});

  @override
  State<GemShell> createState() => _GemShellState();
}

class _GemShellState extends State<GemShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    CommutesScreen(),
    VehiclesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _GemBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _GemBottomNav extends StatelessWidget {
  const _GemBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap(0);
                },
              ),
              _NavItem(
                icon: Icons.route_rounded,
                label: 'Commutes',
                isActive: currentIndex == 1,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap(1);
                },
              ),
              _NavItem(
                icon: Icons.bluetooth_rounded,
                label: 'Vehicles',
                isActive: currentIndex == 2,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap(2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isActive ? 1.15 : 1.0,
              child: Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
