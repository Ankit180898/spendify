import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';

class TopBarContents extends StatelessWidget {
  final String username;
  final String avatarUrl;
  const TopBarContents(
      {super.key, required this.username, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            textAlign: TextAlign.start,
            textScaleFactor: 1.5,
            text: TextSpan(
              text: 'Hello,\n',
              style: normalText(16, AppColor.secondarySoft),
              children: <TextSpan>[
                TextSpan(
                    text: username, style: titleText(20, AppColor.secondary)),
              ],
            ),
          ),
          InkWell(
            onTap: () => controller.signOut(),
            child: const CircleAvatar(
              radius: 30.0,
              backgroundImage: NetworkImage(
                  'https://avatar.iran.liara.run/public/boy',
                  scale: 10),
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
