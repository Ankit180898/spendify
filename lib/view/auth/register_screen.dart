import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/auth_controller/register_controller.dart';
import 'package:spendify/routes/app_pages.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : AppColor.lightBg;
    final cardBg = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final borderColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: Container(
        color: isDark ? AppColor.darkSurface : AppColor.lightSurface,
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.spaceMD,
          horizontal: AppDimens.spaceLG,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: AppTypography.body(textSecondary),
              ),
              TextButton(
                onPressed: () => Get.toNamed(Routes.LOGIN),
                child: Text(
                  'Sign In',
                  style: AppTypography.bodyLarge(AppColor.primary),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceXXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimens.spaceHuge),

              // Header icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColor.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                ),
                child: const Icon(
                  Iconsax.wallet_3,
                  color: Colors.white,
                  size: AppDimens.iconLG,
                ),
              ),
              const SizedBox(height: AppDimens.spaceXXL),
              Text(
                'Create account',
                style: AppTypography.heading1(textPrimary),
              ),
              const SizedBox(height: AppDimens.spaceXS),
              Text(
                'Start tracking your finances today',
                style: AppTypography.body(textSecondary),
              ),

              const SizedBox(height: AppDimens.spaceXXXL),

              // Name field
              Text('Full Name', style: AppTypography.bodySemiBold(textPrimary)),
              const SizedBox(height: AppDimens.spaceSM),
              _buildTextField(
                controller: controller.nameC,
                hint: 'John Doe',
                keyboardType: TextInputType.name,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: AppDimens.spaceLG),

              // Email field
              Text('Email', style: AppTypography.bodySemiBold(textPrimary)),
              const SizedBox(height: AppDimens.spaceSM),
              _buildTextField(
                controller: controller.emailC,
                hint: 'youremail@example.com',
                keyboardType: TextInputType.emailAddress,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: AppDimens.spaceLG),

              // Password field
              Text('Password', style: AppTypography.bodySemiBold(textPrimary)),
              const SizedBox(height: AppDimens.spaceSM),
              Obx(() => _buildTextField(
                    controller: controller.passwordC,
                    hint: '••••••••••••',
                    obscure: controller.isHidden.value,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isHidden.value
                            ? Iconsax.eye
                            : Iconsax.eye_slash4,
                        color: textSecondary,
                        size: AppDimens.iconMD,
                      ),
                      onPressed: () => controller.isHidden.value =
                          !controller.isHidden.value,
                    ),
                  )),

              const SizedBox(height: AppDimens.spaceXXXL),

              // Register button
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.isFalse
                          ? () => controller.register()
                          : null,
                      child: controller.isLoading.isTrue
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: AppTypography.button(Colors.white),
                            ),
                    ),
                  )),

              const SizedBox(height: AppDimens.spaceXXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceLG),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: AppTypography.body(textPrimary),
        cursorColor: AppColor.primary,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppTypography.body(textSecondary),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
