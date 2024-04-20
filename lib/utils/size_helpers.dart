import 'package:flutter/material.dart';

Size displaySize(BuildContext context) {
  // debugPrint('Size = ' + MediaQuery.of(context).size.toString());
  return MediaQuery.of(context).size;
}

double displayHeight(BuildContext context) {
  // debugPrint('Height = ${displaySize(context).height}');
  return displaySize(context).height;
}

double displayWidth(BuildContext context) {
  // debugPrint('Width = ' + displaySize(context).width.toString());
  return displaySize(context).width;
}

double displayFontSize(BuildContext context) {
  // debugPrint('Size = ' + MediaQuery.of(context).size.toString());
  return MediaQuery.of(context).devicePixelRatio;
}
