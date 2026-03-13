import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/auth_controller/login_controller.dart';
import 'package:spendify/routes/app_pages.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final inputBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account?",
                    style: TextStyle(color: textMuted, fontSize: 14)),
                TextButton(
                  onPressed: () => Get.offAllNamed(Routes.REGISTER),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                  child: const Text('Register',
                      style: TextStyle(color: AppColor.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsLight.wallet,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 28),
                Text('Welcome back',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    )),
                const SizedBox(height: 6),
                Text('Sign in to continue to Spendify',
                    style: TextStyle(color: textMuted, fontSize: 14)),
                const SizedBox(height: 36),

                Text('Email',
                    style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _Field(
                  controller: controller.emailC,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  inputBg: inputBg,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Password',
                        style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                    TextButton(
                      onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Forgot password?',
                          style: TextStyle(color: AppColor.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() => _Field(
                      controller: controller.passwordC,
                      hint: '••••••••',
                      obscure: controller.isHidden.value,
                      inputBg: inputBg,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      suffix: GestureDetector(
                        onTap: () => controller.isHidden.value = !controller.isHidden.value,
                        child: PhosphorIcon(
                          controller.isHidden.value
                              ? PhosphorIconsLight.eye
                              : PhosphorIconsLight.eyeSlash,
                          color: textMuted,
                          size: 18,
                        ),
                      ),
                    )),
                const SizedBox(height: 32),

                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.isFalse
                            ? () => controller.login()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColor.primary.withValues(alpha: 0.5),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isLoading.isTrue
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Sign In',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color inputBg;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.hint,
    required this.inputBg,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscure,
                keyboardType: keyboardType,
                style: TextStyle(color: textPrimary, fontSize: 14),
                cursorColor: AppColor.primary,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(color: textMuted, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (suffix != null) ...[const SizedBox(width: 8), suffix!],
          ],
        ),
      );
}
