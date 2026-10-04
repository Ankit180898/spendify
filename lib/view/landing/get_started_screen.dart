import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/auth_controller/login_controller.dart';
import 'package:spendify/widgets/celebration.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginCtrl = Get.put(LoginController());
    final bottom = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.bg,
        body: Column(
          children: [
            // ── Hero ────────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColor.bannerBg,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset('assets/app_logo.png', width: 34, height: 34),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Spendify',
                              style: GoogleFonts.urbanist(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColor.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(child: _HeroShowcase()),
                    ],
                  ),
                ),
              ),
            ),

            // ── Copy + CTA ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Money, made simple.\nAnd a little bit fun.',
                    style: GoogleFonts.urbanist(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary,
                      letterSpacing: -1.0,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Log in seconds, stay on budget, and build streaks that turn good habits into savings.',
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      color: AppColor.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FeaturePill(icon: PhosphorIconsDuotone.lightning, label: 'Quick logging'),
                      _FeaturePill(icon: PhosphorIconsDuotone.shieldCheck, label: 'Smart budgets'),
                      _FeaturePill(icon: PhosphorIconsDuotone.fire, label: 'Streaks & badges'),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: loginCtrl.isGoogleLoading.isTrue
                              ? null
                              : loginCtrl.signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.textPrimary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColor.textPrimary.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: loginCtrl.isGoogleLoading.isTrue
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/google_logo.svg',
                                      width: 18,
                                      height: 18,
                                      colorFilter: const ColorFilter.mode(
                                          Colors.white, BlendMode.srcIn),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      )),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Free forever · Your data stays yours',
                      style: GoogleFonts.urbanist(fontSize: 12, color: AppColor.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final Object icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColor.borderStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, size: 15, color: AppColor.primary, duotoneSecondaryOpacity: 0.3),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero showcase — real app pieces floating gently
// ─────────────────────────────────────────────────────────────────────────────

class _HeroShowcase extends StatefulWidget {
  const _HeroShowcase();

  @override
  State<_HeroShowcase> createState() => _HeroShowcaseState();
}

class _HeroShowcaseState extends State<_HeroShowcase> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _float.dispose();
    _intro.dispose();
    super.dispose();
  }

  /// Each piece bobs on its own phase and pops in on its own delay.
  Widget _piece({
    required Widget child,
    required double phase,
    required double start,
    double amp = 6,
  }) {
    final intro = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, (start + 0.5).clamp(0, 1), curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _intro]),
      builder: (_, c) {
        final dy = math.sin((_float.value + phase) * 2 * math.pi) * amp;
        return Opacity(
          opacity: intro.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy + 20 * (1 - intro.value)),
            child: Transform.scale(scale: 0.9 + 0.1 * intro.value, child: c),
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final cardW = math.min(w - 64, 320.0);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Balance card
          Positioned(
            left: (w - cardW) / 2,
            top: h * 0.22,
            width: cardW,
            child: _piece(phase: 0, start: 0, amp: 4, child: const _MiniBalanceCard()),
          ),
          // Streak chip — top left
          Positioned(
            left: 24,
            top: h * 0.06,
            child: _piece(
              phase: 0.3,
              start: 0.2,
              child: const _FloatingChip(
                leading: PulsingFlame(size: 18),
                text: '12-day streak',
              ),
            ),
          ),
          // XP chip — top right
          Positioned(
            right: 24,
            top: h * 0.11,
            child: _piece(
              phase: 0.6,
              start: 0.3,
              child: const _FloatingChip(
                leading: PhosphorIcon(PhosphorIconsDuotone.lightning,
                    size: 18, color: AppColor.warning, duotoneSecondaryOpacity: 0.35),
                text: '+25 XP',
              ),
            ),
          ),
          // Badge — bottom left
          Positioned(
            left: 30,
            bottom: h * 0.06,
            child: _piece(
              phase: 0.15,
              start: 0.45,
              child: const _FloatingChip(
                leading: PhosphorIcon(PhosphorIconsDuotone.trophy,
                    size: 18, color: AppColor.primary, duotoneSecondaryOpacity: 0.35),
                text: 'Week Warrior',
              ),
            ),
          ),
          // Goal ring — bottom right
          Positioned(
            right: 30,
            bottom: h * 0.03,
            child: _piece(phase: 0.8, start: 0.55, child: const _MiniGoal()),
          ),
        ],
      );
    });
  }
}

class _MiniBalanceCard extends StatelessWidget {
  const _MiniBalanceCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColor.primary.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This month',
                style: GoogleFonts.urbanist(fontSize: 12, color: AppColor.textTertiary)),
            const SizedBox(height: 2),
            Text(
              '₹24,680 left',
              style: GoogleFonts.urbanist(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColor.textPrimary,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: const LinearProgressIndicator(
                value: 0.42,
                minHeight: 7,
                backgroundColor: AppColor.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(AppColor.income),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: _MiniRow(icon: PhosphorIconsDuotone.forkKnife, label: 'Food', amt: '₹3,240', color: AppColor.warning)),
                SizedBox(width: 10),
                Expanded(child: _MiniRow(icon: PhosphorIconsDuotone.bus, label: 'Travel', amt: '₹1,120', color: AppColor.catCar)),
              ],
            ),
          ],
        ),
      );
}

class _MiniRow extends StatelessWidget {
  final Object icon;
  final String label;
  final String amt;
  final Color color;
  const _MiniRow({required this.icon, required this.label, required this.amt, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Center(child: PhosphorIcon(icon, size: 15, color: color, duotoneSecondaryOpacity: 0.3)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.urbanist(fontSize: 11, color: AppColor.textTertiary)),
                Text(amt,
                    style: GoogleFonts.urbanist(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
              ],
            ),
          ),
        ],
      );
}

class _FloatingChip extends StatelessWidget {
  final Widget leading;
  final String text;
  const _FloatingChip({required this.leading, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AppColor.primary.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
          ],
        ),
      );
}

class _MiniGoal extends StatelessWidget {
  const _MiniGoal();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColor.primary.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 0.72,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColor.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(AppColor.primary),
                    ),
                  ),
                  Text('✈️', style: GoogleFonts.urbanist(fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goa trip',
                    style: GoogleFonts.urbanist(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
                Text('72% saved', style: GoogleFonts.urbanist(fontSize: 11, color: AppColor.textSecondary)),
              ],
            ),
          ],
        ),
      );
}
