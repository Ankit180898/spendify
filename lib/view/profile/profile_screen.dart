import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/theme_controller.dart';
import 'package:spendify/routes/app_pages.dart';
import 'package:spendify/view/profile/edit_profile_screen.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final themeCtrl = ThemeController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Profile', style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Avatar + name ─────────────────────────────
            Obx(() {
              final name = ctrl.userName.value;
              final email = ctrl.userEmail.value;
              final initials = _initials(name);
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: AppColor.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Center(child: Text(initials, style: const TextStyle(color: AppColor.primary, fontSize: 18, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(email, style: TextStyle(color: textMuted, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (ctrl.occupation.value.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColor.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(ctrl.occupation.value, style: const TextStyle(color: AppColor.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            Divider(height: 1, color: divColor),

            // ── Stats row ─────────────────────────────────
            Obx(() {
              final fmt = NumberFormat('#,##0', 'en_IN');
              final net = ctrl.totalIncome.value - ctrl.totalExpense.value;
              final isPos = net >= 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    _StatBox(label: 'Transactions', value: '${ctrl.transactions.length}', color: AppColor.primary, isDark: isDark),
                    const SizedBox(width: 10),
                    _StatBox(
                      label: 'Net balance',
                      value: '${isPos ? '+' : '-'}${ctrl.currencySymbol.value}${fmt.format(net.abs())}',
                      color: isPos ? AppColor.income : AppColor.expense,
                      isDark: isDark,
                    ),
                  ],
                ),
              );
            }),

            Divider(height: 1, color: divColor),

            // ── Settings list ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Settings', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
            ),

            _SettingRow(
              icon: PhosphorIconsLight.sliders,
              label: 'Edit Preferences',
              subtitle: 'Currency, occupation, budget & categories',
              trailing: PhosphorIcon(PhosphorIconsLight.caretRight, size: 18, color: textMuted),
              textPrimary: textPrimary,
              textMuted: textMuted,
              divColor: divColor,
              onTap: () => Get.to(() => const EditProfileScreen()),
            ),

            Obx(() => _SettingRow(
              icon: themeCtrl.isDarkMode ? PhosphorIconsLight.moon : PhosphorIconsLight.sun,
              label: 'Appearance',
              trailing: Switch(
                value: themeCtrl.isDarkMode,
                onChanged: (_) => themeCtrl.toggleTheme(),
                activeTrackColor: AppColor.primary,
                inactiveTrackColor: isDark ? AppColor.darkElevated : const Color(0xFFE4E4E7),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
              textPrimary: textPrimary,
              textMuted: textMuted,
              divColor: divColor,
            )),

            _SettingRow(
              icon: PhosphorIconsLight.headset,
              label: 'Help & Support',
              subtitle: 'Report a bug or ask for help',
              trailing: PhosphorIcon(PhosphorIconsLight.caretRight, size: 18, color: textMuted),
              textPrimary: textPrimary,
              textMuted: textMuted,
              divColor: divColor,
              onTap: () => Get.toNamed(Routes.SUPPORT),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: divColor),

            // ── Logout ────────────────────────────────────
            _SettingRow(
              icon: PhosphorIconsLight.signOut,
              label: 'Sign out',
              subtitle: 'Log out of your account',
              iconColor: AppColor.expense,
              labelColor: AppColor.expense,
              trailing: const PhosphorIcon(PhosphorIconsLight.caretRight, size: 18, color: AppColor.expense),
              textPrimary: textPrimary,
              textMuted: textMuted,
              divColor: divColor,
              onTap: () async {
                await ctrl.signOut();
                CustomToast.successToast('Success', 'Logged out');
              },
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final p = name.trim().split(' ');
    return '${p.first.isNotEmpty ? p.first[0] : ''}${p.length > 1 && p.last.isNotEmpty ? p.last[0] : ''}'.toUpperCase();
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _StatBox({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        ],
      ),
    ),
  );
}

class _SettingRow extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final String? subtitle;
  final Widget trailing;
  final Color textPrimary;
  final Color textMuted;
  final Color divColor;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.trailing,
    required this.textPrimary,
    required this.textMuted,
    required this.divColor,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          PhosphorIcon(icon, color: iconColor ?? textMuted, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: labelColor ?? textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!, style: TextStyle(color: textMuted, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    ),
  );
}
