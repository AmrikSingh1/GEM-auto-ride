import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF00E676);       // Spring Green
  static const Color primaryDark = Color(0xFF00B24D);
  static const Color primaryLight = Color(0xFF69FFA8);

  // Accent / System
  static const Color accent = Color(0xFF2979FF);        // Electric Blue
  static const Color accentLight = Color(0xFF75A7FF);

  // Surfaces
  static const Color surface = Color(0xFF121212);       // Deep Charcoal
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color surfaceCard = Color(0xFF252525);
  static const Color surfaceGlass = Color(0x1AFFFFFF);  // 10% white

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF616161);

  // State Colors (for ride states)
  static const Color idle = Color(0xFF616161);
  static const Color detecting = Color(0xFF2979FF);
  static const Color confirming = Color(0xFFFFAB00);
  static const Color inProgress = Color(0xFF00E676);
  static const Color ending = Color(0xFFFF5252);

  // Utility
  static const Color divider = Color(0xFF2A2A2A);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);

  // Gradient stops
  static const List<Color> primaryGradient = [primary, Color(0xFF00BCD4)];
  static const List<Color> accentGradient = [accent, Color(0xFF7C4DFF)];
  static const List<Color> surfaceGradient = [surfaceCard, surface];
}
