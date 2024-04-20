import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/controller/splash/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SplashController());
    return const Scaffold(
      body: Text("CashMate"),
    );
  }
}
