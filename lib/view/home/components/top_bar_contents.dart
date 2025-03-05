import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';

class TopBarContents extends StatelessWidget {
  final HomeController controller = Get.find<HomeController>();

  TopBarContents({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Ensure userName is not empty before accessing its characters
      String initials = '';
      String userName = controller.userName.value;

      if (userName.isNotEmpty) {
        List<String> nameParts = userName.split(' ');
        // Safely get initials, ensuring there are at least two parts
        String firstInitial = nameParts.isNotEmpty && nameParts[0].isNotEmpty
            ? nameParts[0][0]
            : '';
        String lastInitial = nameParts.length > 1 && nameParts.last.isNotEmpty
            ? nameParts.last[0]
            : '';
        initials =
            '$firstInitial$lastInitial'.toUpperCase(); // Combine initials
      } else {
        initials = '??'; // Fallback text if userName is empty
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                // CircleAvatar(
                //   backgroundColor: AppColor.secondary,
                //   child: Text(
                //     initials, // Use the calculated initials
                //     style: const TextStyle(color: Colors.white),
                //   ),
                // ),
                // const SizedBox(
                //   width: 8,
                // ),
                RichText(
                  textScaler: const TextScaler.linear(1),
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    text: 'Welcome Back,\n',
                    style: normalText(
                        16, AppColor.secondaryExtraSoft.withOpacity(0.5)),
                    children: <TextSpan>[
                      TextSpan(
                          text: userName, // Use the userName variable
                          style: titleText(24, AppColor.secondaryExtraSoft)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
