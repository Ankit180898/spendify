import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/model/categories_model.dart';

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
TextStyle mediumTextStyle(double size, Color color) => GoogleFonts.dmSans(
      textStyle: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
      ),
    );
//72 when big
// 48 when mobile size
TextStyle titleText(double size, Color color) => GoogleFonts.dmSans(
      textStyle: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
      ),
    );

//24
TextStyle normalText(double size, Color color) => GoogleFonts.dmSans(
      textStyle:
          TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w400),
    );

  List<CategoriesModel> categoryList = [
    CategoriesModel(name: 'Food & Drinks',  icon: PhosphorIconsLight.forkKnife),
    CategoriesModel(name: 'Groceries',      icon: PhosphorIconsLight.shoppingCart),
    CategoriesModel(name: 'Transport',      icon: PhosphorIconsLight.bus),
    CategoriesModel(name: 'Car',            icon: PhosphorIconsLight.car),
    CategoriesModel(name: 'Shopping',       icon: PhosphorIconsLight.bag),
    CategoriesModel(name: 'Bills & Fees',   icon: PhosphorIconsLight.lightning),
    CategoriesModel(name: 'Health',         icon: PhosphorIconsLight.pill),
    CategoriesModel(name: 'Entertainment',  icon: PhosphorIconsLight.filmSlate),
    CategoriesModel(name: 'Travel',         icon: PhosphorIconsLight.airplane),
    CategoriesModel(name: 'Investments',    icon: PhosphorIconsLight.trendUp),
    CategoriesModel(name: 'Education',      icon: PhosphorIconsLight.graduationCap),
    CategoriesModel(name: 'Subscriptions',  icon: PhosphorIconsLight.receipt),
    CategoriesModel(name: 'Gifts',          icon: PhosphorIconsLight.gift),
    CategoriesModel(name: 'Others',         icon: PhosphorIconsLight.tag),
  ];
