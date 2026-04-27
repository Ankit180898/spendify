import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/upi_capture_controller/upi_capture_controller.dart';

class UpiPermissionScreen extends StatelessWidget {
  const UpiPermissionScreen({super.key});

  static const _supportedApps = [
    ('PhonePe', '💜'),
    ('Google Pay', '🔵'),
    ('Paytm', '🔷'),
    ('Amazon Pay', '🟠'),
    ('BHIM', '🟢'),
    ('WhatsApp Pay', '💚'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : AppColor.lightBg;
    final surface = isDark ? AppColor.darkCard : AppColor.lightCard;
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Back / skip
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Get.find<UpiCaptureController>().markPermissionPrompted();
                    Get.back();
                  },
                  child: Text(
                    'Maybe later',
                    style: AppTypography.body(textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColor.primaryExtraSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: PhosphorIcon(
                    PhosphorIconsLight.lightning,
                    color: AppColor.primary,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Auto-capture\nUPI payments',
                style: AppTypography.heading1(textPrimary).copyWith(fontSize: 28, height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                'Spendify can read UPI payment notifications and log them for you automatically — no manual entry needed.',
                style: AppTypography.body(textSecondary).copyWith(height: 1.6),
              ),
              const SizedBox(height: 32),
              // How it works
              _BenefitRow(
                icon: PhosphorIconsLight.bellRinging,
                title: 'Zero manual entry',
                subtitle: 'Every UPI payment is captured the moment it happens.',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _BenefitRow(
                icon: PhosphorIconsLight.lock,
                title: 'Private & on-device',
                subtitle: 'Notification content is parsed on your phone. Nothing is sent to any server.',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _BenefitRow(
                icon: PhosphorIconsLight.checkCircle,
                title: 'You stay in control',
                subtitle: 'Review every transaction before it\'s saved. Skip anything you don\'t want.',
                isDark: isDark,
              ),
              const SizedBox(height: 32),
              // Supported apps
              Text('Works with', style: AppTypography.label(textSecondary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _supportedApps.map((app) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(app.$2, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(app.$1, style: AppTypography.caption(textSecondary)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const Spacer(),
              // CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final ctrl = Get.find<UpiCaptureController>();
                    await ctrl.requestPermission();
                    // Will return from Settings via AppLifecycleState.resumed
                    Get.back();
                  },
                  icon: const PhosphorIcon(
                    PhosphorIconsLight.shieldCheck,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text('Enable Auto-Capture'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: AppTypography.button(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'You\'ll be taken to Android Settings to grant access.',
                  style: AppTypography.caption(textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final PhosphorIconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColor.primaryExtraSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: PhosphorIcon(icon, color: AppColor.primary, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodySemiBold(textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.caption(textSecondary).copyWith(height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
