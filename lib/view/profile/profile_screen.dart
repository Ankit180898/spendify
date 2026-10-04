import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/upi_capture_controller/upi_capture_controller.dart';
import 'package:spendify/routes/app_pages.dart';
import 'package:spendify/services/progress_service.dart';
import 'package:spendify/view/admin/admin_screen.dart';
import 'package:spendify/view/profile/edit_profile_screen.dart';
import 'package:spendify/widgets/celebration.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: GoogleFonts.urbanist(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    Text(
                      'Your account, progress and settings',
                      style: GoogleFonts.urbanist(fontSize: 13, color: AppColor.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Identity card ────────────────────────────────────
              Obx(() => _IdentityCard(
                    name: ctrl.userName.value,
                    email: ctrl.userEmail.value,
                    occupation: ctrl.occupation.value,
                    imageUrl: ctrl.imageUrl.value,
                  )),

              // ── Progress ─────────────────────────────────────────
              Obx(() {
                final txs = ctrl.allTransactions.toList();
                final p = ProgressService.compute(
                  transactions: txs,
                  monthlyBudget: ctrl.monthlyBudget.value,
                );
                return _LevelCard(progress: p);
              }),

              // ── Stats ────────────────────────────────────────────
              Obx(() {
                final txs = ctrl.allTransactions.toList();
                final p = ProgressService.compute(transactions: txs);
                final net = ctrl.totalIncome.value - ctrl.totalExpense.value;
                final fmt = NumberFormat.compact(locale: 'en_IN');
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: PhosphorIconsDuotone.receipt,
                          color: AppColor.primary,
                          label: 'Logged',
                          value: NumberFormat('#,##0', 'en_IN').format(txs.length),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: PhosphorIconsDuotone.wallet,
                          color: net >= 0 ? AppColor.income : AppColor.expense,
                          label: 'Net balance',
                          value: '${net < 0 ? '−' : ''}${ctrl.currencySymbol.value}${fmt.format(net.abs())}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: PhosphorIconsDuotone.fire,
                          color: const Color(0xFFE07A3F),
                          label: 'Best streak',
                          value: '${p.bestStreak}d',
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // ── Settings ─────────────────────────────────────────
              const _GroupTitle('Settings'),
              _Group(
                children: [
                  _Row(
                    icon: PhosphorIconsDuotone.sliders,
                    color: AppColor.primary,
                    label: 'Preferences',
                    subtitle: 'Currency, occupation, budget & categories',
                    onTap: () => Get.to(() => const EditProfileScreen(),
                        transition: Transition.cupertino),
                  ),
                  if (Platform.isAndroid)
                    Obx(() {
                      final upi = Get.find<UpiCaptureController>();
                      final on = upi.isPermissionGranted.value;
                      return _Row(
                        icon: PhosphorIconsDuotone.bellRinging,
                        color: AppColor.income,
                        label: 'UPI auto-capture',
                        subtitle: on
                            ? 'On — payments are picked up from notifications'
                            : 'Detect UPI payments from notifications',
                        trailing: Switch(
                          value: on,
                          // Android only lets users change notification access in
                          // system settings, so both directions open it.
                          onChanged: (_) => NotificationListenerService.requestPermission(),
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColor.primary,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: AppColor.border,
                          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                        ),
                      );
                    }),
                  Obx(() => ctrl.isAdmin.value
                      ? _Row(
                          icon: PhosphorIconsDuotone.shieldStar,
                          color: AppColor.catCar,
                          label: 'Admin panel',
                          subtitle: 'View and reply to support tickets',
                          onTap: () => Get.to(() => const AdminScreen()),
                        )
                      : const SizedBox.shrink()),
                ],
              ),

              const _GroupTitle('Help'),
              _Group(
                children: [
                  _Row(
                    icon: PhosphorIconsDuotone.headset,
                    color: AppColor.warning,
                    label: 'Help & support',
                    subtitle: 'Report a bug or ask a question',
                    onTap: () => Get.toNamed(Routes.SUPPORT),
                  ),
                ],
              ),

              const _GroupTitle('Account'),
              _Group(
                children: [
                  _Row(
                    icon: PhosphorIconsDuotone.signOut,
                    color: AppColor.textSecondary,
                    label: 'Sign out',
                    onTap: () => _confirmSignOut(context, ctrl),
                  ),
                  _Row(
                    icon: PhosphorIconsDuotone.trash,
                    color: AppColor.expense,
                    label: 'Delete account',
                    labelColor: AppColor.expense,
                    subtitle: 'Permanently remove your account and data',
                    onTap: () => _confirmDelete(context, ctrl),
                  ),
                ],
              ),

              // ── Footer ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: Center(
                  child: Column(
                    children: [
                      Image.asset('assets/brand_mark.png', width: 44, height: 44),
                      const SizedBox(height: 6),
                      Text('Spendify',
                          style: GoogleFonts.urbanist(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.textSecondary)),
                      Text('Made with care in India',
                          style: GoogleFonts.urbanist(fontSize: 11, color: AppColor.textTertiary)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + AppDimens.navBarHeight + 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, HomeController ctrl) async {
    final ok = await _confirmSheet(
      context,
      icon: PhosphorIconsDuotone.signOut,
      color: AppColor.primary,
      title: 'Sign out of Spendify?',
      body: 'Your data stays safe in your account. Sign back in anytime to pick up your streak.',
      confirm: 'Sign out',
    );
    if (ok != true) return;
    await ctrl.signOut();
    CustomToast.successToast('Signed out', 'See you soon!');
  }

  Future<void> _confirmDelete(BuildContext context, HomeController ctrl) async {
    final ok = await _confirmSheet(
      context,
      icon: PhosphorIconsDuotone.warningCircle,
      color: AppColor.expense,
      title: 'Delete your account?',
      body: 'This permanently deletes your account and everything in it — transactions, goals, budgets, bills and badges. This can\'t be undone.',
      confirm: 'Delete forever',
      destructive: true,
    );
    if (ok != true) return;
    await ctrl.deleteAccount();
  }

  Future<bool?> _confirmSheet(
    BuildContext context, {
    required Object icon,
    required Color color,
    required String title,
    required String body,
    required String confirm,
    bool destructive = false,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 14, 24, 24 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColor.border, borderRadius: BorderRadius.circular(100)),
            ),
            const SizedBox(height: 22),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: PhosphorIcon(icon, size: 30, color: color, duotoneSecondaryOpacity: 0.3),
              ),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: AppTypography.body(AppColor.textSecondary)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: destructive ? AppColor.expense : AppColor.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(confirm),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: AppTypography.bodySemiBold(AppColor.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Identity card
// ─────────────────────────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  final String name;
  final String email;
  final String occupation;
  final String imageUrl;

  const _IdentityCard({
    required this.name,
    required this.email,
    required this.occupation,
    required this.imageUrl,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.bannerBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.startsWith('http')
                    ? Image.network(imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _InitialsText(_initials))
                    : _InitialsText(_initials),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Your name' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(fontSize: 13, color: AppColor.textSecondary),
                    ),
                    if (occupation.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          occupation,
                          style: GoogleFonts.urbanist(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Get.to(() => const EditProfileScreen(), transition: Transition.cupertino);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColor.borderStrong),
                  ),
                  child: const Center(
                    child: PhosphorIcon(PhosphorIconsLight.pencilSimple,
                        size: 17, color: AppColor.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _InitialsText extends StatelessWidget {
  final String text;
  const _InitialsText(this.text);

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          text,
          style: GoogleFonts.urbanist(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Level card
// ─────────────────────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final UserProgress progress;
  const _LevelCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final unlocked = p.badges.where((b) => b.unlocked).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColor.borderStrong),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColor.warning.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${p.level}',
                      style: GoogleFonts.urbanist(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColor.warning,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Level ${p.level}',
                          style: AppTypography.caption(AppColor.textTertiary)),
                      Text(
                        p.levelTitle,
                        style: GoogleFonts.urbanist(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulsingFlame(size: 20, active: p.streak > 0),
                    const SizedBox(width: 4),
                    Text(
                      '${p.streak}',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: p.levelProgress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 7,
                        backgroundColor: AppColor.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation(AppColor.warning),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${p.nextLevelXp - p.xp} XP to Lv ${p.level + 1}',
                  style: AppTypography.caption(AppColor.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final b in p.badges)
                  Expanded(
                    child: Opacity(
                      opacity: b.unlocked ? 1 : 0.35,
                      child: Container(
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: b.unlocked ? b.color.withValues(alpha: 0.12) : AppColor.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: PhosphorIcon(b.icon,
                              size: 17,
                              color: b.unlocked ? b.color : AppColor.textTertiary,
                              duotoneSecondaryOpacity: 0.3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${unlocked.length} of ${p.badges.length} badges earned',
              style: AppTypography.caption(AppColor.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small pieces
// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final Object icon;
  final Color color;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.borderStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(icon, size: 20, color: color, duotoneSecondaryOpacity: 0.3),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.urbanist(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(label, style: GoogleFonts.urbanist(fontSize: 11, color: AppColor.textTertiary)),
          ],
        ),
      );
}

class _GroupTitle extends StatelessWidget {
  final String text;
  const _GroupTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Text(
          text,
          style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.heading),
        ),
      );
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.borderStrong),
          ),
          child: Column(children: children),
        ),
      );
}

class _Row extends StatelessWidget {
  final Object icon;
  final Color color;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Row({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    this.labelColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    Text(label, style: AppTypography.bodySemiBold(labelColor ?? AppColor.textPrimary)),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTypography.caption(AppColor.textSecondary)),
                  ],
                ),
              ),
              trailing ??
                  const PhosphorIcon(PhosphorIconsLight.caretRight,
                      size: 15, color: AppColor.textTertiary),
            ],
          ),
        ),
      );
}
