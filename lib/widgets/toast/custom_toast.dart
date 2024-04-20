import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../config/app_color.dart';

class CustomToast {
  static errorToast(String? title, String? message) {
    Get.rawSnackbar(
      duration: const Duration(seconds: 4),
      dismissDirection: DismissDirection.horizontal,
      messageText: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Iconsax.info_circle),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    title ?? "error",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'poppins',
                    ),
                  ),
                ),
                Text(
                  message ?? "Add your error message here",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColor.error,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: 8,
      snackPosition: SnackPosition.TOP,
    );
  }

  static successToast(String? title, String? message) {
    Get.rawSnackbar(
      duration: const Duration(seconds: 4),
      dismissDirection: DismissDirection.horizontal,
      messageText: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
           Icon(Iconsax.chart_success,color: AppColor.primary,),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    title ?? "Success",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'poppins',
                    ),
                  ),
                ),
                Text(
                  message ?? "Add your success message here",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColor.success,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: 8,
      snackPosition: SnackPosition.TOP,
    );
  }
}
