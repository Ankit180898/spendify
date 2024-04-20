import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class TopBarContents extends StatelessWidget {
  final String username;
  final String avatarUrl;
  const TopBarContents(
      {super.key, required this.username, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, $username",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            InkWell(
              onTap: () => Get.toNamed(Routes.PROFILE),
              child: const CircleAvatar(
                radius: 20.0,
                backgroundImage: NetworkImage(
                    'https://avatar.iran.liara.run/public/boy',
                    scale: 10),
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
