import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/splash/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColor.darkBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.darkBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo mark — gradient circle with $ icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppColor.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusXXXL),
                  boxShadow: AppShadows.primaryStrong,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: AppDimens.iconXXL,
                ),
              ),
              const SizedBox(height: AppDimens.spaceXXL),
              Text(
                'Spendify',
                style: AppTypography.display(AppColor.textPrimary),
              ),
              const SizedBox(height: AppDimens.spaceXS),
              Text(
                'Smart money. Clear picture.',
                style: AppTypography.body(AppColor.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
