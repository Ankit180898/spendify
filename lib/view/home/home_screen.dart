import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/routes/app_pages.dart';
import 'package:spendify/view/home/components/transaction_list.dart';
import 'package:spendify/widgets/user_info_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    Get.put(TransactionController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: isDark ? AppColor.darkBg : AppColor.lightBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Flat header — greeting + avatar
          SliverToBoxAdapter(
            child: _HomeHeader(isDark: isDark),
          ),

          // Balance card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.spaceLG, 0, AppDimens.spaceLG, 0),
              child: UserInfoCard(size: 0),
            ),
          ),

          // Budget health section
          SliverToBoxAdapter(child: _BudgetHealthSection(isDark: isDark)),

          // Transaction list
          const SliverToBoxAdapter(child: TransactionsContent(5)),

          // Load more
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spaceLG, vertical: AppDimens.spaceXXL),
              child: Obx(() =>
                  controller.transactions.length >= controller.limit.value
                      ? SizedBox(
                          height: AppDimens.buttonHeight,
                          child: OutlinedButton(
                            onPressed: controller.loadMore,
                            child: Text('Load More',
                                style:
                                    AppTypography.button(AppColor.primary)),
                          ),
                        )
                      : const SizedBox()),
            ),
          ),

          // Spacer for floating nav
          const SliverToBoxAdapter(
            child: SizedBox(height: AppDimens.spaceHuge + AppDimens.spaceLG),
          ),
        ],
      ),
    );
  }
}

// ── Flat header ───────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final bool isDark;
  const _HomeHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final now = DateTime.now();
    final monthYear = DateFormat('MMMM yyyy').format(now);

    return SafeArea(
      bottom: false,
      child: Obx(() {
        final name = controller.userName.value;
        final firstName = name.split(' ').first;
        final initials = _initials(name);

        return Padding(
          padding: const EdgeInsets.fromLTRB(AppDimens.spaceLG,
              AppDimens.spaceLG, AppDimens.spaceLG, AppDimens.spaceXXL),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthYear,
                      style: AppTypography.caption(textSecondary),
                    ),
                    const SizedBox(height: AppDimens.spaceXXS),
                    Text(
                      'Hello, ${firstName.isEmpty ? 'there' : firstName}',
                      style: AppTypography.heading2(textPrimary),
                    ),
                  ],
                ),
              ),

              // Avatar
              GestureDetector(
                onTap: () => Get.toNamed(Routes.PROFILE),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColor.primaryGradient,
                    border: Border.all(
                      color: AppColor.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: AppTypography.bodySemiBold(Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return '$a$b'.toUpperCase();
  }
}

// ── Budget health strip ───────────────────────────────────────────────────────

class _BudgetHealthSection extends StatelessWidget {
  final bool isDark;
  const _BudgetHealthSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GoalsController>()) return const SizedBox.shrink();
    final goalsC = Get.find<GoalsController>();

    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Obx(() {
      if (goalsC.goals.isEmpty) return const SizedBox.shrink();

      // Aggregate all goals
      double totalBudget = 0;
      double totalSpent = 0;
      int overCount = 0;

      for (final goal in goalsC.goals) {
        totalBudget += goal.limitAmount;
        final spent = goalsC.currentSpending(goal);
        totalSpent += spent;
        if (spent > goal.limitAmount) overCount++;
      }

      final progress =
          totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
      final isOver = totalSpent > totalBudget;
      final isNear = !isOver && progress >= 0.85;
      final barColor = isOver
          ? AppColor.expense
          : isNear
              ? AppColor.warning
              : AppColor.primary;

      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.spaceLG, AppDimens.spaceXXL, AppDimens.spaceLG, 0),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.spaceLG),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppDimens.radiusXL),
            border: Border.all(
              color: isOver
                  ? AppColor.expense.withOpacity(0.35)
                  : isNear
                      ? AppColor.warning.withOpacity(0.35)
                      : border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.chart,
                        size: AppDimens.iconSM,
                        color: barColor,
                      ),
                      const SizedBox(width: AppDimens.spaceSM),
                      Text(
                        'Budget Health',
                        style: AppTypography.bodySemiBold(textPrimary),
                      ),
                    ],
                  ),
                  if (overCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColor.expense.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusCircle),
                      ),
                      child: Text(
                        '$overCount over limit',
                        style: AppTypography.label(AppColor.expense),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceMD),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDimens.radiusCircle),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: barColor.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: AppDimens.spaceSM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${fmt.format(totalSpent)} spent',
                    style: AppTypography.caption(textSecondary),
                  ),
                  Text(
                    '₹${fmt.format(totalBudget)} budgeted',
                    style: AppTypography.caption(textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
