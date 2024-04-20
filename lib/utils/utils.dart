import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

enum RotationDirection { clockwise, counterclockwise }

enum StaggeredGridType { square, horizontal, vertical }

extension Direction on RotationDirection {
  bool get isClockwise => this == RotationDirection.clockwise;
}

Widget verticalSpace(double height) {
  return SizedBox(height: height);
}

Widget horizontalSpace(double width) {
  return SizedBox(width: width);
}

extension DurationExtension on int {
  Duration get s => Duration(seconds: this);
  Duration get ms => Duration(milliseconds: this);
}

//30 medium
TextStyle mediumTextStyle(double size, Color color) => GoogleFonts.epilogue(
      textStyle: TextStyle(
        color: color,
        height: 2,
        fontSize: size,
        fontWeight: FontWeight.w700,
      ),
    );
//72 when big
// 48 when mobile size
TextStyle titleText(double size, Color color) => GoogleFonts.inter(
      textStyle: TextStyle(
        color: color,
        height: 1.2,
        fontSize: size,
        fontWeight: FontWeight.bold,
      ),
    );
    
//24
TextStyle normalText(double size, Color color) => GoogleFonts.epilogue(
      textStyle: TextStyle(
          height: 1.5,
          color: color,
          fontSize: size,
          fontWeight: FontWeight.normal),
    );

List<String> categories = [
  'All',
  'Articles',
  'Packages',
  'UI',
  'Projects',
  'YTChannel',
  'News'
];

