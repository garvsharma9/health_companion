import 'package:flutter/material.dart';

class AppTheme {
  // --- LIGHT THEME PALETTE ---
  static const Color bgLight = Color(0xFFF2F2F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF6C6C70);
  static const Color primaryBlueLight = Color(0xFF007AFF);

  // --- DARK THEME PALETTE (Apple visionOS Spatial Glass) ---
  static const Color bgDark = Color(0xFF0C0C10);
  static const Color surfaceDark = Color(0xFF181820);
  static const Color cardDark = Color(0xFF1E1E26);

  // Apple Spatial Vital Colors
  static const Color appleHeartRed = Color(0xFFFF2D55);
  static const Color appleOxygenCyan = Color(0xFF64D2FF);
  static const Color appleTempAmber = Color(0xFFFF9500);
  static const Color visionPurple = Color(0xFFA855F7);

  // Shared Status Accent Colors (Apple iOS / visionOS System Colors)
  static const Color healthyGreen = Color(0xFF30D158);
  static const Color warningAmber = Color(0xFFFF9500);
  static const Color criticalRed = Color(0xFFFF3B30);
  static const Color electricCyan = Color(0xFF0A84FF);

  /// Clean Apple Porcelain Theme (Light Mode)
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: bgLight,
      primaryColor: primaryBlueLight,
      colorScheme: const ColorScheme.light(
        primary: primaryBlueLight,
        secondary: healthyGreen,
        surface: surfaceLight,
        error: criticalRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE5E5EA), width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryBlueLight,
        unselectedItemColor: textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
          letterSpacing: -0.6,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: textPrimaryLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: textSecondaryLight,
        ),
      ),
    );
  }

  /// Apple visionOS Spatial Glassmorphic Dark Theme
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: electricCyan,
      colorScheme: const ColorScheme.dark(
        primary: electricCyan,
        secondary: healthyGreen,
        surface: surfaceDark,
        error: criticalRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E26).withValues(alpha: 0.60),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF12121A),
        selectedItemColor: electricCyan,
        unselectedItemColor: Color(0xFF8E8E93),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.6,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: Color(0xFF9898A0),
        ),
      ),
    );
  }
}
