import 'package:flutter/material.dart';

class AppColor {
  AppColor._();

  // ── BRAND ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF8552FF);       // vibrant violet — unchanged, pops on charcoal
  static const Color primarySoft = Color(0xFFAA88FF);
  static const Color primaryExtraSoft = Color(0x268552FF);
  static const Color primaryGlow = Color(0x408552FF);

  // ── SEMANTIC ──────────────────────────────────────────────────────────────
  static const Color income = Color(0xFF00C896);        // vivid mint-teal
  static const Color incomeSoft = Color(0x2200C896);
  static const Color expense = Color(0xFFFF5370);       // coral-red
  static const Color expenseSoft = Color(0x22FF5370);
  static const Color warning = Color(0xFFFFB300);       // amber
  static const Color warningSoft = Color(0x22FFB300);

  // ── DARK THEME — warm charcoal, zero blue tint ────────────────────────────
  static const Color darkBg = Color(0xFF111110);        // near-black warm charcoal
  static const Color darkSurface = Color(0xFF1C1B1A);   // lifted surface
  static const Color darkCard = Color(0xFF242320);      // card — visible against surface
  static const Color darkElevated = Color(0xFF2E2D2A);  // sheets, bottom bars
  static const Color darkBorder = Color(0xFF383633);    // subtle warm border
  static const Color darkBorderFocus = Color(0xFF8552FF);

  static const Color textPrimary = Color(0xFFF5F4F2);   // warm white
  static const Color textSecondary = Color(0xFF908E88); // warm mid-grey
  static const Color textTertiary = Color(0xFF525048);  // dim warm grey

  // ── LIGHT THEME ───────────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF6F5F3);       // warm off-white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8E6E2);
  static const Color lightBorderFocus = Color(0xFF8552FF);

  static const Color lightTextPrimary = Color(0xFF1A1916);
  static const Color lightTextSecondary = Color(0xFF6B6960);
  static const Color lightTextTertiary = Color(0xFF9A9890);

  // ── CATEGORY COLOURS ──────────────────────────────────────────────────────
  static const Color catInvestments = Color(0xFF8552FF);
  static const Color catHealth = Color(0xFF00C896);
  static const Color catBills = Color(0xFFFF5370);
  static const Color catFood = Color(0xFFFFB300);
  static const Color catCar = Color(0xFF29B6F6);
  static const Color catGroceries = Color(0xFF26D0A0);
  static const Color catGifts = Color(0xFFFF4081);
  static const Color catTransport = Color(0xFF7986CB);

  // ── GRADIENTS ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8552FF), Color(0xFF5B21B6)],
  );

  // Balance card: deep charcoal with a whisper of purple warmth
  static const LinearGradient balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2730), Color(0xFF1A1820)],
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

  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1B1A), Color(0xFF111110)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1B1A), Color(0xFF111110)],
  );

  static const LinearGradient darkGradientAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF242320), Color(0xFF1C1B1A)],
  );

  static final LinearGradient cardGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.08),
      Colors.white.withOpacity(0.03),
    ],
  );

  // Purple to mint accent — for hero elements and charts
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8552FF), Color(0xFF00C896)],
  );

  static const LinearGradient headerGradientDark = darkHeaderGradient;

  // ── CATEGORY COLOUR LOOKUP ────────────────────────────────────────────────
  static const List<Color> _customPalette = [
    Color(0xFF29B6F6),
    Color(0xFF8552FF),
    Color(0xFFFFB300),
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
    if (k.contains('transport') || k.contains('bus') || k.contains('train') || k.contains('cab') || k.contains('uber')) return catTransport;
    if (k.isEmpty) return primary;
    return _customPalette[k.hashCode.abs() % _customPalette.length];
  }

  // ── BACKWARDS COMPATIBILITY ───────────────────────────────────────────────
  static const Color darkBackground = darkBg;
  static const Color darkSurfaceCompat = darkSurface;
  static Color get whiteColor => const Color(0xFFFFFFFF);
  static Color get secondary => const Color(0xFF1C1B1A);
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