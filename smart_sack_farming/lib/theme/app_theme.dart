import 'package:flutter/material.dart';

class AppTheme {
  // Green Palette — Farm-fresh & Natural
  static const Color primary = Color(0xFF2E7D32);       // Green 800
  static const Color primaryDark = Color(0xFF1B5E20);    // Green 900
  static const Color primaryLight = Color(0xFF66BB6A);   // Green 400
  static const Color accent = Color(0xFF43A047);         // Green 600
  static const Color accentLight = Color(0xFFA5D6A7);    // Green 200

  // Gradient Colors
  static const Color gradientStart = Color(0xFF43A047);  // Green 600
  static const Color gradientMid = Color(0xFF2E7D32);    // Green 800
  static const Color gradientEnd = Color(0xFF1B5E20);    // Green 900

  // Surface & Background
  static const Color background = Color(0xFFF1F8E9);    // Light Green 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF6FBF0);

  // Text
  static const Color textDark = Color(0xFF1B3A1B);
  static const Color textMedium = Color(0xFF4A6B4A);
  static const Color textLight = Color(0xFF8EAC8E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFDCE8DC);
  static const Color divider = Color(0xFFE4F0E4);

  // Status
  static const Color success = Color(0xFF388E3C);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);

  // Farmer role color
  static const Color farmerColor = Color(0xFF43A047);
  // Admin role color
  static const Color adminColor = Color(0xFF1B5E20);

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, gradientMid, gradientEnd],
      );

  static LinearGradient get softGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          gradientStart.withAlpha(20),
          gradientEnd.withAlpha(8),
        ],
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: primary.withAlpha(18),
        blurRadius: 20,
        offset: const Offset(0, 8),
      );

  static BoxShadow get buttonShadow => BoxShadow(
        color: primary.withAlpha(60),
        blurRadius: 16,
        offset: const Offset(0, 6),
      );

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: textOnPrimary,
        onSecondary: textOnPrimary,
        onSurface: textDark,
        onError: textOnPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textMedium, fontSize: 14),
        hintStyle: const TextStyle(color: textLight, fontSize: 14),
        prefixIconColor: textLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
