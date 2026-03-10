import 'package:flutter/material.dart';

class AppColor {
  AppColor._();

  // ── BRAND ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);          // violet-700
  static const Color primarySoft = Color(0xFFA78BFA);      // violet-400
  static const Color primaryExtraSoft = Color(0xFFEDE9FE); // violet-100
  static const Color primaryGlow = Color(0x207C3AED);

  // ── SEMANTIC ──────────────────────────────────────────────────────────────
  static const Color income = Color(0xFF059669);       // emerald-600
  static const Color incomeSoft = Color(0x1A059669);
  static const Color expense = Color(0xFFDC2626);      // red-600
  static const Color expenseSoft = Color(0x1ADC2626);
  static const Color warning = Color(0xFFD97706);      // amber-600
  static const Color warningSoft = Color(0x1AD97706);

  // ── DARK THEME ────────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0D0D14);
  static const Color darkSurface = Color(0xFF15151E);
  static const Color darkCard = Color(0xFF1D1D28);
  static const Color darkElevated = Color(0xFF252532);
  static const Color darkBorder = Color(0xFF2A2A3A);
  static const Color darkBorderFocus = Color(0xFF7C3AED);

  static const Color textPrimary = Color(0xFFF2F2FA);
  static const Color textSecondary = Color(0xFF8080A0);
  static const Color textTertiary = Color(0xFF4A4A64);

  // ── LIGHT THEME ───────────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF5F4FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFEAE8F5);
  static const Color lightBorderFocus = Color(0xFF7C3AED);

  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B8A);
  static const Color lightTextTertiary = Color(0xFF9B9BAE);

  // ── CATEGORY COLOURS ──────────────────────────────────────────────────────
  static const Color catInvestments = Color(0xFF7C3AED);
  static const Color catHealth = Color(0xFF059669);
  static const Color catBills = Color(0xFFDC2626);
  static const Color catFood = Color(0xFFD97706);
  static const Color catCar = Color(0xFF0EA5E9);
  static const Color catGroceries = Color(0xFF10B981);
  static const Color catGifts = Color(0xFFEC4899);
  static const Color catTransport = Color(0xFF6366F1);

  // ── GRADIENTS ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
  );

  // Dark indigo luxury card — feels like a physical bank card
  static const LinearGradient balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF047857)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D1D28), Color(0xFF0D0D14)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF15151E), Color(0xFF0D0D14)],
  );

  static const LinearGradient darkGradientAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D1D28), Color(0xFF15151E)],
  );

  static final LinearGradient cardGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.10),
      Colors.white.withOpacity(0.04),
    ],
  );

  static const LinearGradient headerGradientDark = darkHeaderGradient;

  // ── CATEGORY COLOUR LOOKUP ────────────────────────────────────────────────
  static const List<Color> _customPalette = [
    Color(0xFF06B6D4),
    Color(0xFF8B5CF6),
    Color(0xFFEAB308),
    Color(0xFFF43F5E),
    Color(0xFF14B8A6),
    Color(0xFF84CC16),
    Color(0xFFA855F7),
    Color(0xFFFF6B35),
  ];

  static Color categoryColor(String category) {
    final k = category.toLowerCase().trim();
    if (k.contains('invest')) return catInvestments;
    if (k.contains('health') || k.contains('medical')) return catHealth;
    if (k.contains('bill') || k.contains('fee') || k.contains('util')) return catBills;
    if (k.contains('food') || k.contains('drink') || k.contains('restaurant')) return catFood;
    if (k.contains('car') || k.contains('vehicle') || k.contains('fuel')) return catCar;
    if (k.contains('grocer') || k.contains('super') || k.contains('market')) return catGroceries;
    if (k.contains('gift') || k.contains('present')) return catGifts;
    if (k.contains('transport') || k.contains('bus') || k.contains('train') || k.contains('cab') || k.contains('uber')) return catTransport;
    if (k.isEmpty) return primary;
    return _customPalette[k.hashCode.abs() % _customPalette.length];
  }

  // ── BACKWARDS COMPATIBILITY ───────────────────────────────────────────────
  static const Color darkBackground = darkBg;
  static const Color darkSurfaceCompat = darkSurface;
  static Color get whiteColor => const Color(0xFFFFFFFF);
  static Color get secondary => const Color(0xFF1A1A2E);
  static Color get secondarySoft => textSecondary;
  static Color get secondaryExtraSoft => lightBorder;
  static Color get error => expense;
  static Color get success => income;
  static Color get primarySoftCompat => primarySoft;
  static Color get primaryExtraSoftCompat => primaryExtraSoft;
  static LinearGradient get cardGradient => cardGlassGradient;
  static LinearGradient get secondaryGradient => LinearGradient(
        colors: [secondary, secondary.withOpacity(0.5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
