import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';

class TopBarContents extends StatelessWidget {
  const TopBarContents({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            RichText(
              textScaler: const TextScaler.linear(1),
              textAlign: TextAlign.start,
              text: TextSpan(
                text: 'Welcome Back,\n',
                style: normalText(
                    16, AppColor.secondaryExtraSoft.withOpacity(0.5)),
                children: <TextSpan>[
                  TextSpan(
                      text: controller.userName.value,
                      style: titleText(16, AppColor.secondaryExtraSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
