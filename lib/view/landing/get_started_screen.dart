import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/auth_controller/login_controller.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginCtrl = Get.put(LoginController());
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Hero area ─────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColor.primaryExtraSoft,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColor.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/app_logo.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Spendify',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'Take Control of\nYour Finances',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColor.textPrimary,
                          letterSpacing: -1.2,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Track spending, set budgets, and\ngrow your savings — all in one place.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge(AppColor.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),

              // ── CTA area ──────────────────────────────────────────
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google button
                      Obx(() => SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loginCtrl.isGoogleLoading.isTrue
                              ? null
                              : loginCtrl.signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A1A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/google_logo.svg',
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.urbanist(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
