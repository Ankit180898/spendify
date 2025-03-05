import 'package:flutter/material.dart';

class AppColor {
  // Dark Theme Gradients
  static const darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1F38), // Rich dark blue
      Color(0xFF0D1321), // Deep dark blue
    ],
  );

  static const darkGradientAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2C3E50), // Dark blue-gray
      Color(0xFF1A1F38), // Rich dark blue
    ],
  );

  // Card Gradients
  static final cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.1),
      Colors.white.withOpacity(0.05),
    ],
  );
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary.withOpacity(0.5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomLeft,
  );
  static LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondary.withOpacity(0.5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static Color primary = const Color(0xFF7B88FC);
  static Color primarySoft = const Color(0xFFCED3FE);
  static Color primaryExtraSoft = const Color(0xFFEFF3FC);
  static Color whiteColor = Colors.white;
  static Color secondary = const Color(0xFF171717);
  static Color secondarySoft = const Color(0xFF9D9D9D);
  static Color secondaryExtraSoft = const Color(0xFFE9E9E9);
  static Color error = const Color(0xFFD00E0E);
  static Color success = const Color(0xFF16AE26);
  static Color warning = const Color(0xFFEB8600);

  // Solid Colors
  static const darkBackground = Color(0xFF0D1321);
  static const darkSurface = Color(0xFF1A1F38);
  static const darkCard = Color(0xFF242B42);
}
