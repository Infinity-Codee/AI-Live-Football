/// FootAI Insight — App Theme
/// Dark mode with green/gold accents for a premium sports feel.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colors ────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0D1B2A);
  static const Color bgCard = Color(0xFF1B2838);
  static const Color bgSurface = Color(0xFF243447);
  static const Color primary = Color(0xFF1B998B);
  static const Color primaryLight = Color(0xFF2BC4B4);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8960C);
  static const Color accent = Color(0xFF4ECDC4);
  static const Color red = Color(0xFFFF6B6B);
  static const Color green = Color(0xFF51CF66);
  static const Color grey = Color(0xFF8899AA);
  static const Color greyLight = Color(0xFFADBBCC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color live = Color(0xFFFF4444);

  // Win/Draw/Loss colors for gauge
  static const Color homeWin = Color(0xFF51CF66);
  static const Color draw = Color(0xFFFFD43B);
  static const Color awayWin = Color(0xFFFF6B6B);

  // ─── Gradients ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B998B), Color(0xFF2BC4B4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Shadows ───────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // ─── Border Radius ────────────────────────────────────
  static BorderRadius radiusSm = BorderRadius.circular(8);
  static BorderRadius radiusMd = BorderRadius.circular(12);
  static BorderRadius radiusLg = BorderRadius.circular(16);
  static BorderRadius radiusXl = BorderRadius.circular(24);

  // ─── Theme Data ───────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: gold,
      surface: bgCard,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: white),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: white),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: white),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: white),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: greyLight),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: grey),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: white),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: white,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgCard,
      selectedItemColor: primary,
      unselectedItemColor: grey,
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radiusMd),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
