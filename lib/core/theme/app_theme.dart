import 'package:flutter/material.dart';

/// Palet "Ruang Magang": krem hangat, hijau tua, dan aksen coral.
class AppColors {
  static const bg = Color(0xFFF5F2EA);
  static const card = Color(0xFFFCFAF5);
  static const line = Color(0xFFE6E0D2);
  static const green = Color(0xFF0F4A42);
  static const greenSoft = Color(0xFFDCE8E1);
  static const coral = Color(0xFFE2725B);
  static const coralSoft = Color(0xFFFAE5DE);
  static const ink = Color(0xFF1B2B27);
  static const muted = Color(0xFF6B7A75);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      secondary: AppColors.coral,
      surface: AppColors.bg,
    ),
    dividerColor: AppColors.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.greenSoft,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          fontWeight:
              s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected)
              ? AppColors.green
              : AppColors.muted,
        ),
      ),
    ),
  );
}