import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/main.dart';

import '../../config/app_color.dart';
import '../../config/app_theme.dart';

class CustomToast {
  static void _show({
    required Widget icon,
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMD)),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceLG, vertical: AppDimens.spaceMD),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: AppDimens.spaceLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: AppTypography.bodySemiBold(Colors.white)),
                  const SizedBox(height: 2),
                  Text(message, style: AppTypography.caption(Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void errorToast(String? title, String? message) {
    _show(
      icon: const PhosphorIcon(PhosphorIconsFill.info, color: Colors.white),
      title: title ?? 'Error',
      message: message ?? 'Something went wrong',
      backgroundColor: AppColor.expense,
    );
  }

  static void successToast(String? title, String? message) {
    _show(
      icon: const PhosphorIcon(PhosphorIconsFill.checkCircle, color: AppColor.primary),
      title: title ?? 'Success',
      message: message ?? '',
      backgroundColor: AppColor.darkCard,
    );
  }
}
