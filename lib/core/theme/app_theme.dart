import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme provides two distinct themes:
/// - kidTheme(): Playful, rounded, large tap targets (64x64dp)
/// - parentTheme(): Professional, data-dense, standard targets (48x48dp)
class AppTheme {
  AppTheme._();

  // Bucket colors (colorblind accessible)
  static const Color moneyColor = Color(0xFF4CAF50); // Green
  static const Color investmentsColor = Color(0xFF2196F3); // Blue
  static const Color charityColor = Color(0xFFE91E63); // Pink

  // Shared colors
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  /// Kid-friendly theme with Nunito font and playful colors
  static ThemeData kidTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.nunito(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 64), // Large tap target for kids
          textStyle: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Parent theme with Inter font and professional styling
  static ThemeData parentTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48), // Standard Material size
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
