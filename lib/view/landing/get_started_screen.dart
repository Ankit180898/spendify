import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';

import '../../routes/app_pages.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.darkBg,
        body: Column(
          children: [
            // Illustration area with gradient header
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColor.darkGradientAlt,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppDimens.radiusXXXL),
                    bottomRight: Radius.circular(AppDimens.radiusXXXL),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background glow
                    Positioned(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.primary.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/wallet.gif',
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),

            // Text + CTA
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.spaceXXL,
                  AppDimens.spaceXXL,
                  AppDimens.spaceXXL,
                  AppDimens.spaceXXXL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Take Control of\nYour Money',
                      style: AppTypography.display(AppColor.textPrimary),
                    ),
                    const SizedBox(height: AppDimens.spaceMD),
                    Text(
                      'Track income and expenses effortlessly. Get clear insights into where your money goes.',
                      style: AppTypography.bodyLarge(AppColor.textSecondary),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: AppDimens.buttonHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColor.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMD),
                          boxShadow: AppShadows.primaryStrong,
                        ),
                        child: ElevatedButton(
                          onPressed: () =>
                              Get.offAllNamed(Routes.REGISTER),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMD),
                            ),
                          ),
                          child: Text(
                            'Get Started',
                            style: AppTypography.button(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
