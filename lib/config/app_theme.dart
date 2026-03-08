import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendify/config/app_color.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DIMENSIONS
// Single source for every spacing / sizing value in the app.
// ─────────────────────────────────────────────────────────────────────────────
class AppDimens {
  AppDimens._();

  // Spacing (4 pt base grid)
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double spaceXXXL = 32.0;
  static const double spaceHuge = 48.0;

  // Border radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusXXXL = 28.0;
  static const double radiusCircle = 999.0;

  // Icon sizes
  static const double iconXS = 14.0;
  static const double iconSM = 16.0;
  static const double iconMD = 20.0;
  static const double iconLG = 24.0;
  static const double iconXL = 28.0;
  static const double iconXXL = 32.0;
  static const double iconHero = 48.0;

  // Font sizes
  static const double fontXS = 10.0;
  static const double fontSM = 12.0;
  static const double fontMD = 14.0;
  static const double fontLG = 16.0;
  static const double fontXL = 18.0;
  static const double fontXXL = 20.0;
  static const double fontXXXL = 24.0;
  static const double fontDisplay = 32.0;
  static const double fontHero = 48.0;

  // Component heights
  static const double buttonHeight = 52.0;
  static const double inputHeight = 56.0;
  static const double navBarHeight = 68.0;
  static const double categoryItemSize = 76.0;

  // Padding presets
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: spaceLG);
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceXL);
  static const EdgeInsets inputPadding =
      EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceMD);
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY
// All text styles in the app derived from DM Sans.
// ─────────────────────────────────────────────────────────────────────────────
class AppTypography {
  AppTypography._();

  static TextStyle hero(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontHero,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1.5,
        height: 1.1,
      );

  static TextStyle display(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontDisplay,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1.0,
        height: 1.2,
      );

  static TextStyle heading1(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontXXXL,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
        height: 1.3,
      );

  static TextStyle heading2(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontXXL,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle heading3(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontXL,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      );

  static TextStyle bodyLarge(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontLG,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      );

  static TextStyle body(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontMD,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodySemiBold(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontMD,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.5,
      );

  static TextStyle caption(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontSM,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle captionSemiBold(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontSM,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
        height: 1.4,
      );

  static TextStyle label(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontXS,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
        height: 1.3,
      );

  static TextStyle button(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontLG,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );

  // ── Amount styles — tabular figures prevent digit-width jitter ──────────────
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle amountHero(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontHero,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1.5,
        height: 1.1,
        fontFeatures: _tabular,
      );

  static TextStyle amountDisplay(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontDisplay,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1.0,
        height: 1.2,
        fontFeatures: _tabular,
      );

  static TextStyle amountMedium(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontXXL,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
        fontFeatures: _tabular,
      );

  static TextStyle amountSmall(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontLG,
        fontWeight: FontWeight.w600,
        color: color,
        fontFeatures: _tabular,
      );

  static TextStyle bodySemiBoldTabular(Color color) => GoogleFonts.dmSans(
        fontSize: AppDimens.fontMD,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.5,
        fontFeatures: _tabular,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHADOWS
// ─────────────────────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get cardDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get cardLight => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get primary => [
        BoxShadow(
          color: AppColor.primaryGlow,
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get primaryStrong => [
        BoxShadow(
          color: AppColor.primary.withOpacity(0.45),
          blurRadius: 32,
          offset: const Offset(0, 10),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get income => [
        BoxShadow(
          color: AppColor.income.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get expense => [
        BoxShadow(
          color: AppColor.expense.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.dmSans().fontFamily,
      scaffoldBackgroundColor: AppColor.darkBg,
      primaryColor: AppColor.primary,
      colorScheme: ColorScheme.dark(
        primary: AppColor.primary,
        secondary: AppColor.primarySoft,
        surface: AppColor.darkSurface,
        error: AppColor.expense,
        onPrimary: Colors.white,
        onSurface: AppColor.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColor.textPrimary),
        actionsIconTheme: IconThemeData(color: AppColor.textSecondary),
        titleTextStyle: AppTypography.heading2(AppColor.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColor.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(color: AppColor.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(color: AppColor.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(color: AppColor.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(color: AppColor.expense),
        ),
        hintStyle: AppTypography.body(AppColor.textTertiary),
        labelStyle: AppTypography.caption(AppColor.textSecondary),
        floatingLabelStyle: AppTypography.caption(AppColor.primary),
        contentPadding: AppDimens.inputPadding,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColor.primary.withOpacity(0.35),
          minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          ),
          textStyle: AppTypography.button(Colors.white),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: AppDimens.inputPadding,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.primary,
          side: const BorderSide(color: AppColor.primary, width: 1.5),
          minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          ),
          textStyle: AppTypography.button(AppColor.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.primary,
          textStyle: AppTypography.bodyLarge(AppColor.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSM),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColor.darkCard,
        selectedColor: AppColor.primary,
        disabledColor: AppColor.darkCard,
        labelStyle: AppTypography.body(AppColor.textPrimary),
        side: BorderSide(color: AppColor.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceMD,
          vertical: AppDimens.spaceXS,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColor.darkSurface,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: AppColor.textTertiary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: AppDimens.fontXS,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: AppDimens.fontXS,
          fontWeight: FontWeight.w400,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColor.darkBorder,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColor.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.darkElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
        ),
        titleTextStyle: AppTypography.heading2(AppColor.textPrimary),
        contentTextStyle: AppTypography.body(AppColor.textSecondary),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.darkElevated,
        contentTextStyle: AppTypography.body(AppColor.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColor.textSecondary,
        textColor: AppColor.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColor.textSecondary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColor.primary,
        selectionColor: AppColor.primary.withOpacity(0.3),
        selectionHandleColor: AppColor.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColor.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColor.primary : AppColor.darkBorder,
        ),
      ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.dmSans().fontFamily,
      scaffoldBackgroundColor: AppColor.lightBg,
      primaryColor: AppColor.primary,
      colorScheme: ColorScheme.light(
        primary: AppColor.primary,
        secondary: AppColor.primarySoft,
        surface: AppColor.lightSurface,
        error: AppColor.expense,
        onPrimary: Colors.white,
        onSurface: AppColor.lightTextPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColor.lightTextPrimary),
        actionsIconTheme: IconThemeData(color: AppColor.lightTextSecondary),
        titleTextStyle: AppTypography.heading2(AppColor.lightTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColor.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(color: AppColor.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(color: AppColor.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(color: AppColor.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(color: AppColor.expense),
        ),
        hintStyle: AppTypography.body(AppColor.lightTextTertiary),
        labelStyle: AppTypography.caption(AppColor.lightTextSecondary),
        floatingLabelStyle: AppTypography.caption(AppColor.primary),
        contentPadding: AppDimens.inputPadding,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColor.primary.withOpacity(0.35),
          minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          ),
          textStyle: AppTypography.button(Colors.white),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: AppDimens.inputPadding,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.primary,
          side: const BorderSide(color: AppColor.primary, width: 1.5),
          minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          ),
          textStyle: AppTypography.button(AppColor.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.primary,
          textStyle: AppTypography.bodyLarge(AppColor.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSM),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColor.lightBg,
        selectedColor: AppColor.primary,
        labelStyle: AppTypography.body(AppColor.lightTextPrimary),
        side: BorderSide(color: AppColor.lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceMD,
          vertical: AppDimens.spaceXS,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColor.lightSurface,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: AppColor.lightTextTertiary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: AppDimens.fontXS,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: AppDimens.fontXS,
          fontWeight: FontWeight.w400,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColor.lightBorder,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColor.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
        ),
        titleTextStyle: AppTypography.heading2(AppColor.lightTextPrimary),
        contentTextStyle: AppTypography.body(AppColor.lightTextSecondary),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.lightTextPrimary,
        contentTextStyle: AppTypography.body(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColor.lightTextSecondary,
        textColor: AppColor.lightTextPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
      ),
      iconTheme: IconThemeData(color: AppColor.lightTextSecondary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColor.primary,
        selectionColor: AppColor.primary.withOpacity(0.2),
        selectionHandleColor: AppColor.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColor.lightTextTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColor.primary : AppColor.lightBorder,
        ),
      ),
    );
  }
}
