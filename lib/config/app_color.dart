import 'package:flutter/cupertino.dart';

class AppColor {
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary.withOpacity(0.5)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
  static Color primary = const Color(0xFF8691FC);
  static Color primarySoft = const Color(0xFFCED3FE);
  static Color primaryExtraSoft = const Color(0xFFEFF3FC);
  static Color secondary = const Color(0xFF171717);
  static Color secondarySoft = const Color(0xFF9D9D9D);
  static Color secondaryExtraSoft = const Color(0xFFE9E9E9);
  static Color error = const Color(0xFFD00E0E);
  static Color success = const Color(0xFF16AE26);
  static Color warning = const Color(0xFFEB8600);

}