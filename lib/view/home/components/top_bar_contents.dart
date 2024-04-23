import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';

class TopBarContents extends StatelessWidget {
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
            InkWell(
              onTap: () => controller.signOut(),
              child: const CircleAvatar(
                radius: 24.0,
                backgroundImage: NetworkImage(
                    'https://avatar.iran.liara.run/public/boy',
                    scale: 10),
                backgroundColor: Colors.transparent,
              ),
            ),
            horizontalSpace(8.0),
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
