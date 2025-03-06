import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    CategoriesModel(name: 'Investments', icon: Icons.trending_up),
    CategoriesModel(name: 'Health', icon: Icons.medical_services_outlined),
    CategoriesModel(name: 'Bills & Fees', icon: Icons.receipt_long),
    CategoriesModel(name: 'Food & Drinks', icon: Icons.restaurant),
    CategoriesModel(name: 'Car', icon: Icons.directions_car),
    CategoriesModel(name: 'Groceries', icon: Icons.shopping_cart),
    CategoriesModel(name: 'Gifts', icon: Icons.card_giftcard),
    CategoriesModel(name: 'Transport', icon: Icons.transit_enterexit),
  ];
