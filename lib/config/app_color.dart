import 'package:flutter/material.dart';

class AppColor {
  AppColor._();

  // ── FOUNDATION ────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFF6F5FA);            // Ghost White
  static const Color surface = Color(0xFFFFFFFF);        // Pure white
  static const Color surfaceVariant = Color(0xFFF0EEF5); // Lifted surface
  static const Color border = Color(0xFFE6E2DC);
  static const Color borderFocus = Color(0xFF212121);

  // ── PRIMARY ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF212121);        // Eerie Black
  static const Color primarySoft = Color(0xFFD8DFE9);    // Alice Blue
  static const Color primaryExtraSoft = Color(0xFFEEF1F7);

  // ── ACCENT PALETTE ────────────────────────────────────────────────────────
  static const Color accentYellow = Color(0xFFEFF0A3);   // Vanilla
  static const Color accentBlue = Color(0xFFD8DFE9);     // Alice Blue
  static const Color accentGreen = Color(0xFFCFDECA);    // Honeydew

  // ── SEMANTIC ──────────────────────────────────────────────────────────────
  static const Color income = Color(0xFF00C896);
  static const Color incomeSoft = Color(0xFFCFDECA);     // Honeydew
  static const Color expense = Color(0xFFFF5370);
  static const Color expenseSoft = Color(0xFFFFE8EC);
  static const Color warning = Color(0xFFF5A623);
  static const Color warningSoft = Color(0xFFFFF4E0);

  // ── TYPOGRAPHY ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);    // Eerie Black
  static const Color textSecondary = Color(0xFF6B6860);
  static const Color textTertiary = Color(0xFF9E9C96);

  // ── CATEGORY COLOURS ─────────────────────────────────────────────────────
  static const Color catInvestments = Color(0xFF6B5BFF);
  static const Color catHealth = Color(0xFF00C896);
  static const Color catBills = Color(0xFFFF5370);
  static const Color catFood = Color(0xFFF5A623);
  static const Color catCar = Color(0xFF4BAFD6);
  static const Color catGroceries = Color(0xFF26D0A0);
  static const Color catGifts = Color(0xFFFF4081);
  static const Color catTransport = Color(0xFF7986CB);

  // ── GRADIENTS ─────────────────────────────────────────────────────────────
  static const LinearGradient balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF212121), Color(0xFF404040)],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C896), Color(0xFF009E78)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5370), Color(0xFFD63050)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF212121), Color(0xFF00C896)],
  );

  // ── CATEGORY COLOUR LOOKUP ────────────────────────────────────────────────
  static const List<Color> _customPalette = [
    Color(0xFF4BAFD6),
    Color(0xFF6B5BFF),
    Color(0xFFF5A623),
    Color(0xFFFF5370),
    Color(0xFF00C896),
    Color(0xFF69F0AE),
    Color(0xFFAA44FF),
    Color(0xFFFF6E40),
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
    if (k.contains('transport') || k.contains('bus') || k.contains('train') ||
        k.contains('cab') || k.contains('uber')) {
      return catTransport;
    }
    if (k.isEmpty) return primary;
    return _customPalette[k.hashCode.abs() % _customPalette.length];
  }

  // ── BACKWARDS COMPATIBILITY ───────────────────────────────────────────────
  // Keeps existing widget code compiling while screens are rewritten.
  // All dark tokens now resolve to light equivalents.
  static const Color darkBg = bg;
  static const Color darkBackground = bg;
  static const Color darkSurface = surface;
  static const Color darkCard = surface;
  static const Color darkElevated = surfaceVariant;
  static const Color darkBorder = border;
  static const Color darkBorderFocus = borderFocus;
  static const Color primaryGlow = Color(0x00000000);

  static const Color lightBg = bg;
  static const Color lightSurface = surface;
  static const Color lightCard = surface;
  static const Color lightBorder = border;
  static const Color lightBorderFocus = borderFocus;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color lightTextTertiary = textTertiary;

  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bg, surface],
  );
  static const LinearGradient darkGradient = darkHeaderGradient;
  static const LinearGradient darkGradientAlt = darkHeaderGradient;
  static const LinearGradient headerGradientDark = darkHeaderGradient;

  static Color get whiteColor => const Color(0xFFFFFFFF);
  static Color get secondary => primary;
  static Color get secondarySoft => textSecondary;
  static Color get secondaryExtraSoft => border;
  static Color get error => expense;
  static Color get success => income;
  static Color get primarySoftCompat => primarySoft;
  static Color get primaryExtraSoftCompat => primaryExtraSoft;
  static LinearGradient get cardGradient => balanceCardGradient;
  static LinearGradient get cardGlassGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xCCFFFFFF), Color(0x99FFFFFF)],
      );
  static LinearGradient get secondaryGradient => LinearGradient(
        colors: [primary, primary.withValues(alpha: 0.5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
