import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF1A1A2E);
  static const surface = Color(0xFF16213E);
  static const primary = Color(0xFF0F3460);
  static const accent = Color(0xFFE94560);
  static const textPrimary = Color(0xFFEEEEEE);
  static const textSecondary = Color(0xFF9E9E9E);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFE94560);
  static const coin = Color(0xFFFFD700);
  static const gem = Color(0xFF9C27B0);
  static const team1 = Color(0xFF2196F3);
  static const team2 = Color(0xFFFF5722);
  static const rookie = Color(0xFF42A5F5);
  static const tanko = Color(0xFFEF5350);
  static const spark = Color(0xFFFFEE58);
  static const flora = Color(0xFF66BB6A);
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.surface, elevation: 0),
        cardTheme: const CardThemeData(color: AppColors.surface, elevation: 2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );

  static Color characterColor(String characterId) {
    return switch (characterId) {
      'rookie' => AppColors.rookie,
      'tanko' => AppColors.tanko,
      'spark' => AppColors.spark,
      'flora' => AppColors.flora,
      _ => AppColors.textSecondary,
    };
  }

  static Color teamColor(int teamId) {
    return teamId == 1 ? AppColors.team1 : AppColors.team2;
  }
}
