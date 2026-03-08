import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USER INFO CARD  — hero balance card shown at the top of the home screen.
// Inspired by Copilot's deep-navy gradient card with coloured stat tiles.
// ─────────────────────────────────────────────────────────────────────────────
class UserInfoCard extends StatelessWidget {
  final double size; // kept for API compatibility

  const UserInfoCard({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final fmt = NumberFormat('#,##0.00', 'en_IN');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.spaceXXL),
      decoration: BoxDecoration(
        gradient: AppColor.balanceCardGradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
        boxShadow: AppShadows.primaryStrong,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label row ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: AppTypography.captionSemiBold(
                  Colors.white.withOpacity(0.65),
                ),
              ),
              Obx(() => _VisibilityChip(
                    isVisible: controller.isAmountVisible.value,
                    onTap: controller.toggleVisibility,
                  )),
            ],
          ),

          const SizedBox(height: AppDimens.spaceSM),

          // ── Balance amount ──────────────────────────
          Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  key: ValueKey(controller.isAmountVisible.value),
                  controller.isAmountVisible.value
                      ? '₹${fmt.format(controller.totalBalance.value)}'
                      : '₹ ••••••',
                  style: AppTypography.amountDisplay(Colors.white),
                ),
              )),

          const SizedBox(height: AppDimens.spaceXXL),

          // ── Income / Expense tiles ──────────────────
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Income',
                      value: controller.isAmountVisible.value
                          ? '₹${fmt.format(controller.totalIncome.value)}'
                          : '₹ •••••',
                      icon: Iconsax.arrow_up_3,
                      iconColor: AppColor.income,
                    ),
                  ),
                  // divider
                  Container(
                    width: 1,
                    height: 40,
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppDimens.spaceXL),
                    color: Colors.white.withOpacity(0.15),
                  ),
                  Expanded(
                    child: _StatTile(
                      label: 'Expenses',
                      value: controller.isAmountVisible.value
                          ? '₹${fmt.format(controller.totalExpense.value)}'
                          : '₹ •••••',
                      icon: Iconsax.arrow_down,
                      iconColor: AppColor.expense,
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────

class _VisibilityChip extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onTap;
  const _VisibilityChip({required this.isVisible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceMD,
          vertical: AppDimens.spaceXS + 2,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVisible ? Iconsax.eye : Iconsax.eye_slash,
              color: Colors.white,
              size: AppDimens.iconSM,
            ),
            const SizedBox(width: AppDimens.spaceXS),
            Text(
              isVisible ? 'Hide' : 'Show',
              style: AppTypography.caption(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppDimens.radiusSM),
          ),
          child: Icon(icon, color: iconColor, size: AppDimens.iconSM),
        ),
        const SizedBox(width: AppDimens.spaceSM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTypography.caption(Colors.white.withOpacity(0.6))),
            const SizedBox(height: 1),
            Text(value, style: AppTypography.amountSmall(Colors.white)),
          ],
        ),
      ],
    );
  }
}
