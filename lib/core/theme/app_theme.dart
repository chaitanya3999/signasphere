import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBrand = Color(0xFF6C63FF); // Vibrant Violet
  static const Color secondaryBrand = Color(0xFF00D2D3); // Cyan
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF757575);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F0F1E); // Deep Navy/Black
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBrand, secondaryBrand],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glass UI Constants
  static const double glassBlur = 20.0;
  static const double glassOpacityLight = 0.1;
  static const double glassOpacityDark = 0.15;
  static const double glassBorderOpacity = 0.1;
  static const BorderRadius glassBorderRadius = BorderRadius.all(Radius.circular(24));
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryBrand,
      colorScheme: const ColorScheme.light(
        primary: primaryBrand,
        secondary: secondaryBrand,
        surface: lightSurface,
        background: lightBackground,
        onBackground: lightTextPrimary,
        onSurface: lightTextPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      iconTheme: const IconThemeData(color: lightTextPrimary),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryBrand,
      colorScheme: const ColorScheme.dark(
        primary: primaryBrand,
        secondary: secondaryBrand,
        surface: darkSurface,
        background: darkBackground,
        onBackground: darkTextPrimary,
        onSurface: darkTextPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),
      iconTheme: const IconThemeData(color: darkTextPrimary),
    );
  }
}
