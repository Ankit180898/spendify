
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/auth_controller/login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.primary.withValues(alpha: 0.10),
                      ),
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    Image.asset(
                      'assets/app_logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'Welcome to Spendify',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to track your finances',
                  style: TextStyle(color: textMuted, fontSize: 15),
                ),

                const Spacer(flex: 2),

                // Google button
                Obx(() => _SocialButton(
                        onTap: controller.isGoogleLoading.isFalse &&
                                controller.isAppleLoading.isFalse
                            ? controller.signInWithGoogle
                            : null,
                        isLoading: controller.isGoogleLoading.isTrue,
                        label: 'Continue with Google',
                        icon: _GoogleIcon(),
                        cardBg: cardBg,
                        border: border,
                        textPrimary: textPrimary,
                      )),
                const SizedBox(height: 12),

                // Apple button (iOS only)
                // if (Platform.isIOS)
                //   Obx(() => _SocialButton(
                //         onTap: controller.isGoogleLoading.isFalse &&
                //                 controller.isAppleLoading.isFalse
                //             ? controller.signInWithApple
                //             : null,
                //         isLoading: controller.isAppleLoading.isTrue,
                //         label: 'Continue with Apple',
                //         icon: Icon(
                //           Icons.apple,
                //           color: textPrimary,
                //           size: 22,
                //         ),
                //         cardBg: cardBg,
                //         border: border,
                //         textPrimary: textPrimary,
                //       )),

                const Spacer(flex: 1),

                Text(
                  'By signing in, you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textMuted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;
  final Widget icon;
  final Color cardBg;
  final Color border;
  final Color textPrimary;

  const _SocialButton({
    required this.onTap,
    required this.isLoading,
    required this.label,
    required this.icon,
    required this.cardBg,
    required this.border,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColor.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 22, height: 22, child: icon),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/google_logo.svg', width: 20, height: 20);
  }
}
