import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPENDIFY COLOR SYSTEM  — Five Cents-inspired redesign
// Teal primary, emerald income, clean red expense.
// Warm off-white light mode; deep slate dark mode.
// ─────────────────────────────────────────────────────────────────────────────

class AppColor {
  AppColor._();

  // ── BRAND ─────────────────────────────────────────────────────────────────
  /// Teal — clean, professional, budget-app feel.
  static const Color primary = Color(0xFF0D9488);
  static const Color primarySoft = Color(0xFF14B8A6);
  static const Color primaryExtraSoft = Color(0xFFCCFBF1);
  static const Color primaryGlow = Color(0x1A0D9488);

  // ── SEMANTIC ──────────────────────────────────────────────────────────────
  static const Color income = Color(0xFF10B981);      // emerald
  static const Color incomeSoft = Color(0x1A10B981);

  static const Color expense = Color(0xFFEF4444);     // clean red
  static const Color expenseSoft = Color(0x1AEF4444);

  static const Color warning = Color(0xFFF59E0B);     // amber
  static const Color warningSoft = Color(0x1AF59E0B);

  // ── DARK THEME ────────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0C1118);
  static const Color darkSurface = Color(0xFF161C26);
  static const Color darkCard = Color(0xFF1D2433);
  static const Color darkElevated = Color(0xFF25303F);
  static const Color darkBorder = Color(0xFF2A3445);
  static const Color darkBorderFocus = Color(0xFF354360);

  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF7A8FAA);
  static const Color textTertiary = Color(0xFF415068);

  // ── LIGHT THEME ───────────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF2F6F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFDDE8E5);
  static const Color lightBorderFocus = Color(0xFFACC8C3);

  static const Color lightTextPrimary = Color(0xFF0D1F1C);
  static const Color lightTextSecondary = Color(0xFF4D6B66);
  static const Color lightTextTertiary = Color(0xFF92AEA9);

  // ── CATEGORY COLOURS ──────────────────────────────────────────────────────
  static const Color catInvestments = Color(0xFF0D9488);  // teal
  static const Color catHealth = Color(0xFF10B981);       // emerald
  static const Color catBills = Color(0xFFEF4444);        // red
  static const Color catFood = Color(0xFFF59E0B);         // amber
  static const Color catCar = Color(0xFF0EA5E9);          // sky
  static const Color catGroceries = Color(0xFF22C55E);    // green
  static const Color catGifts = Color(0xFFEC4899);        // pink
  static const Color catTransport = Color(0xFF8B5CF6);    // violet

  // ── GRADIENTS ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D9488), Color(0xFF0A7A70)],
  );

  static const LinearGradient balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D9488), Color(0xFF075E57)],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D2433), Color(0xFF0C1118)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161C26), Color(0xFF0C1118)],
  );

  static const LinearGradient darkGradientAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D2433), Color(0xFF161C26)],
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
  static Color categoryColor(String category) {
    final k = category.toLowerCase().trim();
    if (k.contains('invest')) return catInvestments;
    if (k.contains('health') || k.contains('medical')) return catHealth;
    if (k.contains('bill') || k.contains('fee') || k.contains('util'))
      return catBills;
    if (k.contains('food') || k.contains('drink') || k.contains('restaurant'))
      return catFood;
    if (k.contains('car') || k.contains('vehicle') || k.contains('fuel'))
      return catCar;
    if (k.contains('grocer') || k.contains('super') || k.contains('market'))
      return catGroceries;
    if (k.contains('gift') || k.contains('present')) return catGifts;
    if (k.contains('transport') || k.contains('bus') ||
        k.contains('train') || k.contains('cab') || k.contains('uber'))
      return catTransport;
    return primary;
  }

  // ── BACKWARDS COMPATIBILITY ───────────────────────────────────────────────
  static const Color darkBackground = darkBg;
  static const Color darkSurfaceCompat = darkSurface;
  static Color get whiteColor => const Color(0xFFFFFFFF);
  static Color get secondary => const Color(0xFF171717);
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
