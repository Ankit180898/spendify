import 'package:flutter/material.dart';

class AppColor {
  AppColor._();

  // ── FOUNDATION ────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFF8F6F3);            // Warm cream
  static const Color surface = Color(0xFFFFFFFF);        // Pure white
  static const Color surfaceVariant = Color(0xFFF3EEE9); // Warm lifted surface
  static const Color border = Color(0xFFE6DDD5);
  static const Color borderStrong = Color(0xFFD3C7BE);  // Outlined cards
  static const Color borderFocus = Color(0xFF86695B);

  // ── PRIMARY ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF86695B);        // Mocha
  static const Color primarySoft = Color(0xFFEADFD7);    // Latte
  static const Color primaryExtraSoft = Color(0xFFF4EDE7);
  static const Color heading = Color(0xFF8E7A6E);        // Taupe section titles
  static const Color bannerBg = Color(0xFFF2E9E3);       // Promo banner blush

  // ── ACCENT PALETTE ────────────────────────────────────────────────────────
  static const Color accentYellow = Color(0xFFF6E8C9);   // Butter
  static const Color accentBlue = Color(0xFFE6E0F0);     // Lavender
  static const Color accentGreen = Color(0xFFDCE6D3);    // Sage

  // ── SEMANTIC ──────────────────────────────────────────────────────────────
  static const Color income = Color(0xFF4F9A74);         // Sage green
  static const Color incomeSoft = Color(0xFFDCE9DF);
  static const Color expense = Color(0xFFCB5F55);        // Terracotta
  static const Color expenseSoft = Color(0xFFF7E3E0);
  static const Color warning = Color(0xFFD99A4E);
  static const Color warningSoft = Color(0xFFF8EBD9);

  // ── TYPOGRAPHY ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2E2622);    // Espresso
  static const Color textSecondary = Color(0xFF75685F);
  static const Color textTertiary = Color(0xFFA79A91);

  // ── CATEGORY COLOURS ─────────────────────────────────────────────────────
  static const Color catInvestments = Color(0xFF8C6FA8);
  static const Color catHealth = Color(0xFF4F9A74);
  static const Color catBills = Color(0xFFCB5F55);
  static const Color catFood = Color(0xFFD99A4E);
  static const Color catCar = Color(0xFF6E8CA8);
  static const Color catGroceries = Color(0xFF5E8F8A);
  static const Color catGifts = Color(0xFFC46A86);
  static const Color catTransport = Color(0xFF7C82B0);

  // ── GRADIENTS ─────────────────────────────────────────────────────────────
  static const LinearGradient balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9A7E70), Color(0xFF6F5649)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF86695B), Color(0xFFA48A7C)],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5FAA84), Color(0xFF3F8462)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9766C), Color(0xFFB24E45)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF86695B), Color(0xFF4F9A74)],
  );

  // ── CATEGORY COLOUR LOOKUP ────────────────────────────────────────────────
  static const List<Color> _customPalette = [
    Color(0xFF6E8CA8),
    Color(0xFF8C6FA8),
    Color(0xFFD99A4E),
    Color(0xFFCB5F55),
    Color(0xFF4F9A74),
    Color(0xFF5E8F8A),
    Color(0xFF9A7BB5),
    Color(0xFFB9775A),
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
