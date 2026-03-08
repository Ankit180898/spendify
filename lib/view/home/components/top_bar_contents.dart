import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/routes/app_pages.dart';

class TopBarContents extends StatelessWidget {
  final HomeController controller = Get.find<HomeController>();

  TopBarContents({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final name = controller.userName.value;
      final firstName = name.split(' ').first;
      final initials = _initials(name);

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceXXL,
          AppDimens.spaceHuge,
          AppDimens.spaceXXL,
          AppDimens.spaceLG,
        ),
        child: Row(
          children: [
            // Greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: AppTypography.caption(
                        Colors.white.withOpacity(0.65)),
                  ),
                  const SizedBox(height: AppDimens.spaceXXS),
                  Text(
                    firstName.isEmpty ? 'Friend' : firstName,
                    style: AppTypography.heading2(Colors.white),
                  ),
                ],
              ),
            ),

            // Avatar — taps to profile
            GestureDetector(
              onTap: () => Get.toNamed(Routes.PROFILE),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA09AFF), Color(0xFF7C73FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTypography.bodySemiBold(Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return '$a$b'.toUpperCase();
  }
}
