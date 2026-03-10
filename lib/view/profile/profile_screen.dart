import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/theme_controller.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final themeCtrl = ThemeController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColor.darkBg : AppColor.lightBg;
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final borderColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Profile', style: AppTypography.heading2(textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + name ───────────────────────
            _buildAvatarSection(controller, cardBg, textPrimary,
                textSecondary, borderColor),

            const SizedBox(height: AppDimens.spaceLG),

            // ── Balance summary ─────────────────────
            _buildBalanceSection(
                controller, cardBg, textPrimary, textSecondary, borderColor),

            const SizedBox(height: AppDimens.spaceLG),

            // ── Recent transactions ─────────────────
            _buildRecentTransactions(controller, cardBg, textPrimary,
                textSecondary, borderColor, isDark),

            const SizedBox(height: AppDimens.spaceLG),

            // ── Preferences ────────────────────────
            _buildPreferences(themeCtrl, isDark, cardBg, textPrimary,
                textSecondary, borderColor),

            const SizedBox(height: AppDimens.spaceLG),

            // ── Logout ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await controller.signOut();
                  CustomToast.successToast('Success', 'Logged out successfully');
                },
                icon: const Icon(Iconsax.logout,
                    color: AppColor.expense, size: AppDimens.iconMD),
                label: Text(
                  'Logout',
                  style: AppTypography.button(AppColor.expense),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColor.expense, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: MediaQuery.of(context).padding.bottom +
                  AppDimens.navBarHeight +
                  AppDimens.spaceLG,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section builders ────────────────────────────────────────────────────────

  Widget _buildAvatarSection(
    HomeController controller,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceXXL),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
        border: Border.all(color: borderColor),
      ),
      child: Obx(() {
        final name = controller.userName.value;
        final initials = _initials(name);
        return Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColor.primary,
              child: Text(
                initials,
                style: AppTypography.heading2(Colors.white),
              ),
            ),
            const SizedBox(width: AppDimens.spaceLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.heading3(textPrimary)),
                  const SizedBox(height: AppDimens.spaceXXS),
                  Text(controller.userEmail.value,
                      style: AppTypography.body(textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBalanceSection(
    HomeController controller,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final fmt = NumberFormat('#,##0.00', 'en_IN');

    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceXXL),
      decoration: BoxDecoration(
        gradient: AppColor.balanceCardGradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: AppTypography.caption(Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(height: AppDimens.spaceSM),
          Obx(() => Text(
                '₹${fmt.format(controller.totalBalance.value)}',
                style: AppTypography.amountDisplay(Colors.white),
              )),
          const SizedBox(height: AppDimens.spaceXXL),
          Row(
            children: [
              Expanded(
                child: _BalanceChip(
                  label: 'Income',
                  value: Obx(() =>
                      Text('₹${fmt.format(controller.totalIncome.value)}')),
                  color: AppColor.income,
                ),
              ),
              const SizedBox(width: AppDimens.spaceLG),
              Expanded(
                child: _BalanceChip(
                  label: 'Expenses',
                  value: Obx(() =>
                      Text('₹${fmt.format(controller.totalExpense.value)}')),
                  color: AppColor.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
    HomeController controller,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimens.spaceXXL,
                AppDimens.spaceXXL, AppDimens.spaceXXL, AppDimens.spaceLG),
            child:
                Text('Recent Transactions', style: AppTypography.heading3(textPrimary)),
          ),
          Obx(() {
            if (controller.transactions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppDimens.spaceXXL),
                child: Center(
                  child: Text('No transactions yet',
                      style: AppTypography.body(textSecondary)),
                ),
              );
            }
            final recent = controller.transactions.take(5).toList();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) =>
                  Divider(color: borderColor, height: 1),
              itemBuilder: (context, i) {
                final t = recent[i];
                final isExpense = t['type'] == 'expense';
                final amtColor =
                    isExpense ? AppColor.expense : AppColor.income;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spaceXXL,
                    vertical: AppDimens.spaceXS,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: amtColor.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusSM),
                    ),
                    child: Icon(
                      isExpense
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: amtColor,
                      size: AppDimens.iconMD,
                    ),
                  ),
                  title: Text(t['description']?.toString() ?? '',
                      style: AppTypography.bodyLarge(textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    DateFormat('MMM d, y')
                        .format(DateTime.parse(t['date'])),
                    style: AppTypography.caption(textSecondary),
                  ),
                  trailing: Text(
                    '${isExpense ? '-' : '+'}₹${t['amount']}',
                    style: AppTypography.bodySemiBold(amtColor),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPreferences(
    ThemeController themeCtrl,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimens.spaceXXL,
                AppDimens.spaceXXL, AppDimens.spaceXXL, AppDimens.spaceLG),
            child: Text('Preferences', style: AppTypography.heading3(textPrimary)),
          ),
          Divider(color: borderColor, height: 1),
          Obx(() => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spaceXXL,
                  vertical: AppDimens.spaceXS,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                  ),
                  child: Icon(
                    themeCtrl.isDarkMode ? Iconsax.moon : Iconsax.sun_1,
                    color: AppColor.primary,
                    size: AppDimens.iconMD,
                  ),
                ),
                title: Text(
                  themeCtrl.isDarkMode ? 'Dark Mode' : 'Light Mode',
                  style: AppTypography.bodyLarge(textPrimary),
                ),
                subtitle: Text(
                  'Switch app appearance',
                  style: AppTypography.caption(textSecondary),
                ),
                trailing: Switch.adaptive(
                  value: themeCtrl.isDarkMode,
                  onChanged: (_) => themeCtrl.toggleTheme(),
                  activeColor: AppColor.primary,
                ),
              )),
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last =
        parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────────

class _BalanceChip extends StatelessWidget {
  final String label;
  final Widget value;
  final Color color;

  const _BalanceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceMD,
        vertical: AppDimens.spaceSM,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.caption(Colors.white.withOpacity(0.7))),
          const SizedBox(height: AppDimens.spaceXXS),
          DefaultTextStyle(
            style: AppTypography.amountSmall(Colors.white),
            child: value,
          ),
        ],
      ),
    );
  }
}
