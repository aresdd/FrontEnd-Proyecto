import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.sky,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: AppColors.neutral900,
      primary: AppColors.skyDark,
      onPrimary: Colors.white,
      secondary: AppColors.sky,
      onSecondary: Colors.white,
      tertiary: AppColors.neutral600,
      error: AppColors.accentRose,
    );
    return _base(scheme, Brightness.light).copyWith(
      scaffoldBackgroundColor: AppColors.skyLight,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: AppColors.skyLight,
        foregroundColor: AppColors.neutral900,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral900,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        shadowColor: AppColors.neutral900.withValues(alpha: 0.06),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.sky,
      brightness: Brightness.dark,
      surface: AppColors.darkSurface,
      onSurface: AppColors.neutral50,
      primary: AppColors.sky,
      onPrimary: AppColors.neutral900,
      secondary: AppColors.skyDark,
      onSecondary: Colors.white,
      tertiary: AppColors.neutral300,
      error: AppColors.accentRose,
    );
    return _base(scheme, Brightness.dark).copyWith(
      scaffoldBackgroundColor: AppColors.neutral900,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: AppColors.neutral900,
        foregroundColor: AppColors.neutral50,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral50,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.darkSurfaceVariant,
        shadowColor: Colors.black54,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
      splashFactory: InkRipple.splashFactory,
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: scheme.primary,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
