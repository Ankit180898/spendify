import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/upi_capture_controller/upi_capture_controller.dart';

class UpiPermissionScreen extends StatelessWidget {
  const UpiPermissionScreen({super.key});

  static const _supportedApps = [
    ('PhonePe', Color(0xFF5F259F)),
    ('Google Pay', Color(0xFF4285F4)),
    ('Paytm', Color(0xFF00BAF2)),
    ('Amazon Pay', Color(0xFFFF9900)),
    ('BHIM', Color(0xFF4F9A74)),
    ('WhatsApp Pay', Color(0xFF25D366)),
  ];

  void _later() {
    HapticFeedback.selectionClick();
    Get.find<UpiCaptureController>().markPermissionPrompted();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _later,
                    child: Text('Maybe later',
                        style: AppTypography.bodySemiBold(AppColor.textSecondary)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  const _CaptureDemo(),
                  const SizedBox(height: 24),
                  Text(
                    'Log UPI payments\nautomatically',
                    style: GoogleFonts.urbanist(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary,
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'When a UPI payment notification arrives, Spendify picks up the amount and merchant so you can save it in one tap.',
                    style: GoogleFonts.urbanist(
                        fontSize: 15, color: AppColor.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 20),

                  // ── Benefits ─────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColor.borderStrong),
                    ),
                    child: const Column(
                      children: [
                        _Benefit(
                          icon: PhosphorIconsDuotone.lightning,
                          color: AppColor.warning,
                          title: 'No more typing',
                          subtitle: 'Payments show up ready to save the moment they happen.',
                        ),
                        Divider(height: 1, color: AppColor.border, indent: 66, endIndent: 14),
                        _Benefit(
                          icon: PhosphorIconsDuotone.lockSimple,
                          color: AppColor.income,
                          title: 'Private, on your phone',
                          subtitle: 'Notifications are read on-device. We never upload them.',
                        ),
                        Divider(height: 1, color: AppColor.border, indent: 66, endIndent: 14),
                        _Benefit(
                          icon: PhosphorIconsDuotone.checkCircle,
                          color: AppColor.catCar,
                          title: 'You approve everything',
                          subtitle: 'Review each payment before it\'s saved — or skip it.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Supported apps ───────────────────────────────
                  Text('Works with',
                      style: GoogleFonts.urbanist(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.heading)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _supportedApps
                        .map((a) => Container(
                              padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                              decoration: BoxDecoration(
                                color: AppColor.surface,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: AppColor.borderStrong),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(color: a.$2, shape: BoxShape.circle),
                                    child: Center(
                                      child: Text(a.$1[0],
                                          style: GoogleFonts.urbanist(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(a.$1,
                                      style: GoogleFonts.urbanist(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.textPrimary)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            // ── CTA ─────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await Get.find<UpiCaptureController>().requestPermission();
                        // Returns from Settings via AppLifecycleState.resumed
                        Get.back();
                      },
                      icon: const PhosphorIcon(PhosphorIconsBold.bellRinging,
                          color: Colors.white, size: 18),
                      label: const Text('Turn on auto-capture'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll be taken to Android settings to allow notification access.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(AppColor.textTertiary),
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

/// Animated example: a UPI notification arrives, then becomes a Spendify entry.
class _CaptureDemo extends StatefulWidget {
  const _CaptureDemo();

  @override
  State<_CaptureDemo> createState() => _CaptureDemoState();
}

class _CaptureDemoState extends State<_CaptureDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double t, double a, double b) =>
      Curves.easeOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: AppColor.bannerBg,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          final notifIn = _seg(t, 0.0, 0.18);
          final arrowIn = _seg(t, 0.28, 0.40);
          final entryIn = Curves.easeOutBack.transform(((t - 0.40) / 0.18).clamp(0.0, 1.0));
          final fadeOut = 1 - _seg(t, 0.88, 1.0);

          return Opacity(
            opacity: fadeOut,
            child: Column(
              children: [
                // Notification
                Opacity(
                  opacity: notifIn,
                  child: Transform.translate(
                    offset: Offset(0, -16 * (1 - notifIn)),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.primary.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                                color: Color(0xFF5F259F), shape: BoxShape.circle),
                            child: Center(
                              child: Text('P',
                                  style: GoogleFonts.urbanist(
                                      fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PhonePe · now',
                                    style: GoogleFonts.urbanist(
                                        fontSize: 11, color: AppColor.textTertiary)),
                                Text('₹250 paid to Swiggy',
                                    style: GoogleFonts.urbanist(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: arrowIn,
                  child: Transform.translate(
                    offset: Offset(0, 6 * (1 - arrowIn)),
                    child: const PhosphorIcon(PhosphorIconsBold.arrowDown,
                        size: 18, color: AppColor.primary),
                  ),
                ),
                const SizedBox(height: 8),
                // Spendify entry
                Opacity(
                  opacity: entryIn.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * entryIn,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColor.income.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColor.categoryColor('Food & Drinks').withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: PhosphorIcon(PhosphorIconsDuotone.forkKnife,
                                  size: 16,
                                  color: AppColor.categoryColor('Food & Drinks'),
                                  duotoneSecondaryOpacity: 0.3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Swiggy · Food & Drinks',
                                    style: GoogleFonts.urbanist(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.textPrimary)),
                                Text('Ready to save in Spendify',
                                    style: GoogleFonts.urbanist(
                                        fontSize: 11, color: AppColor.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                                color: AppColor.income, shape: BoxShape.circle),
                            child: const Center(
                              child: PhosphorIcon(PhosphorIconsBold.check,
                                  size: 13, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final Object icon;
  final Color color;
  final String title;
  final String subtitle;

  const _Benefit({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: PhosphorIcon(icon, size: 19, color: color, duotoneSecondaryOpacity: 0.3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodySemiBold(AppColor.textPrimary)),
                  Text(subtitle,
                      style: AppTypography.caption(AppColor.textSecondary).copyWith(height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );
}
