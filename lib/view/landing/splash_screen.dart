import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/splash/splash_controller.dart';
import 'package:spendify/utils/utils.dart';

class SplashScreen extends StatelessWidget {

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final controller = Get.put(SplashController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value:  SystemUiOverlayStyle(
        statusBarColor: AppColor.secondary, // Set status bar color
        statusBarIconBrightness: Brightness.light, // Icon color
    ),
    child: Scaffold(
      backgroundColor: AppColor.secondary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Image.asset("assets/splash1.png"),
                Text(
                  "Spendify",
                  style: titleText(24, AppColor.secondaryExtraSoft),
                )
              ],
            ),
          ),
        ],
      ),
    )
    );
  }
}
