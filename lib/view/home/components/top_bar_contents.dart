import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/routes/app_pages.dart';

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
        String firstInitial = nameParts.isNotEmpty && nameParts[0].isNotEmpty ? nameParts[0][0] : '';
        String lastInitial = nameParts.length > 1 && nameParts.last.isNotEmpty ? nameParts.last[0] : '';
        initials = '$firstInitial$lastInitial'.toUpperCase(); // Combine initials
      } else {
        initials = '??'; // Fallback text if userName is empty
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Welcome text and user name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // User Avatar
            InkWell(
              onTap: () => Get.toNamed(Routes.PROFILE),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColor.primary,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
