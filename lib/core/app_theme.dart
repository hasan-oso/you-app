import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Royal Identity Colors
  static const Color primaryColor = Color(0xFF6A0DAD); // Royal Purple
  static const Color accentColor = Color(0xFFFFD700); // Gold
  static const Color backgroundColor = Color(0xFF0F0F0F); // Deep Space Black

  // State Colors (Unified System)
  static const Color successColor = Color(0xFF00D9A3); // Neon Green
  static const Color warningColor = Color(0xFFFF9500); // Vibrant Orange
  static const Color dangerColor = Color(0xFFFF3B30); // Neon Red
  
  // Neutral Colors
  static const Color neutralLight = Color(0xFFE0E0E0); // Light Grey
  static const Color neutralDark = Color(0xFF2A2A3E); // Dark Grey

  static ThemeData get lightTheme {
    // Current design is dark-focused, but providing a structure for potential light mode or just default.
    // For now, mapping everything to the requested dark aesthetic since that seems to be the core identity.
    return darkTheme;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // Luxury Neon Glass Protocols
  static BoxDecoration get neonGlassDecoration => BoxDecoration(
    color: const Color(0xFF0F0F0F).withValues(alpha: 0.6), // Semi-transparent black
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.1), // Subtle default border
      width: 1.5,
    ),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.05),
        Colors.white.withValues(alpha: 0.01),
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.4),
        blurRadius: 15,
        offset: const Offset(0, 10),
      ),
    ],
  );
  
  static BoxDecoration get activeNeonBorder => neonGlassDecoration.copyWith(
    border: Border.all(
      color: accentColor.withValues(alpha: 0.6),
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: accentColor.withValues(alpha: 0.25),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );
}
