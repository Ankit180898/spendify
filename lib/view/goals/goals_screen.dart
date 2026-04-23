import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/recurring_bills_controller/recurring_bills_controller.dart';
import 'package:spendify/controller/savings_controller/savings_controller.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/model/recurring_bill_model.dart';
import 'package:spendify/model/savings_goal_model.dart';
import 'package:spendify/model/spending_goal_model.dart';
import 'package:spendify/utils/utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GOALS SCREEN
// Two-tab design inspired by Five Cents Monthly Budget:
//   Tab 1 — Budget: category spending limits with summary overview
//   Tab 2 — Savings: goal-based savings tracker
// ─────────────────────────────────────────────────────────────────────────────

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (!Get.isRegistered<SavingsController>()) Get.put(SavingsController());
    if (!Get.isRegistered<RecurringBillsController>()) {
      Get.put(RecurringBillsController());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final tabBorder = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    final spendingC = Get.find<GoalsController>();
    final savingsC = Get.find<SavingsController>();
    final billsC = Get.find<RecurringBillsController>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Goals', style: AppTypography.heading2(textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColor.primary,
          indicatorWeight: 2,
          labelColor: AppColor.primary,
          unselectedLabelColor:
              isDark ? AppColor.textSecondary : AppColor.lightTextSecondary,
          labelStyle: AppTypography.bodySemiBold(AppColor.primary),
          unselectedLabelStyle: AppTypography.body(
              isDark ? AppColor.textSecondary : AppColor.lightTextSecondary),
          dividerColor: tabBorder,
          tabs: const [
            Tab(text: 'Budget'),
            Tab(text: 'Savings'),
            Tab(text: 'Bills'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BudgetTab(controller: spendingC, isDark: isDark),
          _SavingsTab(controller: savingsC, isDark: isDark),
          _BillsTab(controller: billsC, isDark: isDark),
        ],
      ),
    );
  }

}

// Public entry-point called from BottomNav's universal + button.
void showGoalsAddPicker(BuildContext ctx) {
  final spendingC = Get.find<GoalsController>();
  final savingsC = Get.find<SavingsController>();
  final billsC = Get.find<RecurringBillsController>();
  final isDark = Theme.of(ctx).brightness == Brightness.dark;
  final bg = isDark ? AppColor.darkCard : Colors.white;
  final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
  final textSecondary =
      isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

  showModalBottomSheet(
    context: ctx,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('What would you like to add?',
              style: AppTypography.bodySemiBold(textPrimary)),
          const SizedBox(height: 16),
          _PickerOption(
            icon: PhosphorIconsLight.chartPieSlice,
            label: 'Budget Limit',
            subtitle: 'Set a spending cap for a category',
            isDark: isDark,
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AddBudgetSheet(controller: spendingC),
              );
            },
          ),
          const SizedBox(height: 10),
          _PickerOption(
            icon: PhosphorIconsLight.piggyBank,
            label: 'Savings Goal',
            subtitle: 'Track progress toward a financial goal',
            isDark: isDark,
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AddSavingsSheet(controller: savingsC),
              );
            },
          ),
          const SizedBox(height: 10),
          _PickerOption(
            icon: PhosphorIconsLight.calendarCheck,
            label: 'Recurring Bill',
            subtitle: 'Track a subscription or regular payment',
            isDark: isDark,
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AddBillSheet(controller: billsC),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColor.darkBg : const Color(0xFFF5F5F5);
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColor.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.bodySemiBold(textPrimary)),
                  Text(subtitle,
                      style: AppTypography.caption(textSecondary)),
                ],
              ),
            ),
            Icon(PhosphorIconsLight.caretRight,
                color: textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Budget Tab ────────────────────────────────────────────────────────────────

class _BudgetTab extends StatelessWidget {
  final GoalsController controller;
  final bool isDark;

  const _BudgetTab({required this.controller, required this.isDark});

  /// This month's total expenses computed from allTransactions.
  double _thisMonthExpense(HomeController hc) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return hc.allTransactions.where((t) {
      if (t['type'] != 'expense') return false;
      final d = t['parsedDate'] as DateTime?;
      if (d == null) return false;
      return !d.isBefore(start) && !d.isAfter(end);
    }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final dividerColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    final hc = Get.find<HomeController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final monthlyBudget = hc.monthlyBudget.value;
      final hasMonthlyBudget = monthlyBudget > 0;
      final hasGoals = controller.goals.isNotEmpty;

      // If nothing to show at all
      if (!hasMonthlyBudget && !hasGoals) {
        return _EmptyView(
          icon: PhosphorIconsLight.wallet,
          title: 'No budget set yet',
          subtitle:
              'Set a monthly budget in your preferences, or add category spending limits here.',
          cta: 'Tap + to add a limit · Swipe left to delete',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      }

      // Compute category-limit totals
      double totalLimit = 0;
      double totalSpent = 0;
      for (final g in controller.goals) {
        totalLimit += g.limitAmount;
        totalSpent += controller.currentSpending(g);
      }
      final totalProgress =
          totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;

      final monthExpense = _thisMonthExpense(hc);

      return RefreshIndicator(
        onRefresh: controller.fetchGoals,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // ── Monthly budget overview card (from onboarding/prefs) ──────
            if (hasMonthlyBudget)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.spaceLG, AppDimens.spaceLG, AppDimens.spaceLG, 0),
                child: _MonthlyBudgetCard(
                  budget: monthlyBudget,
                  spent: monthExpense,
                  isDark: isDark,
                ),
              ),

            // ── Category limits summary card ──────────────────────────────
            if (hasGoals) ...[
              Padding(
                padding: const EdgeInsets.all(AppDimens.spaceLG),
                child: _BudgetSummaryCard(
                  totalLimit: totalLimit,
                  totalSpent: totalSpent,
                  totalProgress: totalProgress,
                  isDark: isDark,
                ),
              ),
              // Category rows
              Container(
                clipBehavior: Clip.antiAlias,
                margin:
                    const EdgeInsets.symmetric(horizontal: AppDimens.spaceLG),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < controller.goals.length; i++) ...[
                      _BudgetRow(
                        goal: controller.goals[i],
                        controller: controller,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      if (i < controller.goals.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: dividerColor,
                          indent: AppDimens.spaceLG + 36 + AppDimens.spaceMD,
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spaceLG),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDimens.spaceLG),
                child: Text(
                  'Swipe left on a row to delete a budget limit.',
                  style: AppTypography.caption(isDark
                      ? AppColor.textTertiary
                      : AppColor.lightTextTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else if (hasMonthlyBudget) ...[
              // Has monthly budget but no category limits
              const SizedBox(height: AppDimens.spaceLG),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDimens.spaceLG),
                child: Text(
                  'Tap + to add category spending limits.',
                  style: AppTypography.caption(isDark
                      ? AppColor.textTertiary
                      : AppColor.lightTextTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Budget Summary Card (Five Cents hero header) ──────────────────────────────

class _BudgetSummaryCard extends StatelessWidget {
  final double totalLimit;
  final double totalSpent;
  final double totalProgress;
  final bool isDark;

  const _BudgetSummaryCard({
    required this.totalLimit,
    required this.totalSpent,
    required this.totalProgress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final remaining = totalLimit - totalSpent;
    final isOver = remaining < 0;
    final barColor = totalProgress >= 1.0
        ? AppColor.expense
        : totalProgress >= 0.8
            ? AppColor.warning
            : AppColor.income;
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF9F9FB);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceXL),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(PhosphorIconsLight.calendar,
                  color: textMuted, size: AppDimens.iconSM),
              const SizedBox(width: AppDimens.spaceXS),
              Text(monthName, style: AppTypography.caption(textMuted)),
            ],
          ),
          const SizedBox(height: AppDimens.spaceXL),
          Row(
            children: [
              Expanded(
                child: _SummaryCol(
                  label: 'Budgeted',
                  value:
                      '${Get.find<HomeController>().currencySymbol.value}${fmt.format(totalLimit)}',
                  color: textPrimary,
                ),
              ),
              Expanded(
                child: _SummaryCol(
                  label: 'Spent',
                  value:
                      '${Get.find<HomeController>().currencySymbol.value}${fmt.format(totalSpent)}',
                  color: textPrimary,
                ),
              ),
              Expanded(
                child: _SummaryCol(
                  label: isOver ? 'Over by' : 'Remaining',
                  value:
                      '${Get.find<HomeController>().currencySymbol.value}${fmt.format(remaining.abs())}',
                  color: isOver ? AppColor.expense : AppColor.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceXL),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
            child: LinearProgressIndicator(
              value: totalProgress,
              minHeight: 5,
              backgroundColor: barColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: AppDimens.spaceXS),
          Text(
            '${(totalProgress * 100).toStringAsFixed(0)}% of total budget used',
            style: AppTypography.label(textMuted),
          ),
        ],
      ),
    );
  }
}

class _SummaryCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCol({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label(color.withValues(alpha: 0.5))),
        const SizedBox(height: AppDimens.spaceXXS),
        Text(value,
            style: AppTypography.bodySemiBold(color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ── Monthly Budget Card (from onboarding/preferences) ────────────────────────

class _MonthlyBudgetCard extends StatelessWidget {
  final double budget;
  final double spent;
  final bool isDark;

  const _MonthlyBudgetCard({
    required this.budget,
    required this.spent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final sym = Get.find<HomeController>().currencySymbol.value;
    final remaining = budget - spent;
    final isOver = remaining < 0;
    final progress = (spent / budget).clamp(0.0, 1.0);
    final barColor = progress >= 1.0
        ? AppColor.expense
        : progress >= 0.8
            ? AppColor.warning
            : AppColor.income;

    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF9F9FB);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceXL),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const PhosphorIcon(
                  PhosphorIconsLight.wallet,
                  color: AppColor.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text('Monthly Budget',
                  style: AppTypography.bodySemiBold(textPrimary)),
              const Spacer(),
              Text(monthName, style: AppTypography.caption(textMuted)),
            ],
          ),
          const SizedBox(height: AppDimens.spaceXL),
          Row(
            children: [
              Expanded(
                child: _SummaryCol(
                  label: 'Budget',
                  value: '$sym${fmt.format(budget)}',
                  color: textPrimary,
                ),
              ),
              Expanded(
                child: _SummaryCol(
                  label: 'Spent',
                  value: '$sym${fmt.format(spent)}',
                  color: textPrimary,
                ),
              ),
              Expanded(
                child: _SummaryCol(
                  label: isOver ? 'Over by' : 'Remaining',
                  value: '$sym${fmt.format(remaining.abs())}',
                  color: isOver ? AppColor.expense : AppColor.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceXL),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: barColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: AppDimens.spaceXS),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% of monthly budget used',
            style: AppTypography.label(textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Budget Row (compact Five Cents-style table row) ───────────────────────────

class _BudgetRow extends StatelessWidget {
  final SpendingGoal goal;
  final GoalsController controller;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _BudgetRow({
    required this.goal,
    required this.controller,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final spent = controller.currentSpending(goal);
    final progress =
        goal.limitAmount > 0 ? (spent / goal.limitAmount).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > goal.limitAmount;
    final isNear = !isOver && progress >= 0.8;
    final barColor = isOver
        ? AppColor.expense
        : isNear
            ? AppColor.warning
            : AppColor.income;
    final iconBg = isDark ? AppColor.darkElevated : const Color(0xFFF4F4F8);
    final iconFg = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.spaceXXL),
        color: AppColor.expense.withValues(alpha: 0.10),
        child: const PhosphorIcon(PhosphorIconsLight.trash,
            color: AppColor.expense),
      ),
      onDismissed: (_) => controller.deleteGoal(goal.id),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceLG),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppDimens.radiusSM),
              ),
              child: PhosphorIcon(
                _categoryIcon(goal.category),
                color: iconFg,
                size: AppDimens.iconMD,
              ),
            ),
            const SizedBox(width: AppDimens.spaceMD),
            // Name + progress bar + amounts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.category == 'All'
                              ? 'Total Spending'
                              : goal.category,
                          style: AppTypography.bodySemiBold(textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${Get.find<HomeController>().currencySymbol.value}${fmt.format(spent)} / ${Get.find<HomeController>().currencySymbol.value}${fmt.format(goal.limitAmount)}',
                        style: AppTypography.caption(
                            isOver ? AppColor.expense : textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.spaceXS),
                  LayoutBuilder(builder: (context, constraints) {
                    return Stack(children: [
                      Container(
                        height: 4,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusCircle),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        height: 4,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusCircle),
                        ),
                      ),
                    ]);
                  }),
                  const SizedBox(height: AppDimens.spaceXXS),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% used'
                    '${isOver ? ' · Over limit' : isNear ? ' · Near limit' : ''}',
                    style: AppTypography.label(
                      isOver
                          ? AppColor.expense
                          : isNear
                              ? AppColor.warning
                              : isDark
                                  ? AppColor.textTertiary
                                  : AppColor.lightTextTertiary,
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

  PhosphorIconData _categoryIcon(String category) {
    if (category == 'All') return PhosphorIconsLight.wallet;
    final k = category.toLowerCase();
    if (k.contains('invest')) return PhosphorIconsLight.chartBar;
    if (k.contains('health') || k.contains('medical')) {
      return PhosphorIconsLight.heart;
    }
    if (k.contains('bill') || k.contains('fee')) {
      return PhosphorIconsLight.receipt;
    }
    if (k.contains('food') || k.contains('drink')) {
      return PhosphorIconsLight.coffee;
    }
    if (k.contains('car') || k.contains('vehicle')) {
      return PhosphorIconsLight.car;
    }
    if (k.contains('grocer')) return PhosphorIconsLight.shoppingCart;
    if (k.contains('gift')) return PhosphorIconsLight.gift;
    if (k.contains('transport')) return PhosphorIconsLight.bus;
    return PhosphorIconsLight.squaresFour;
  }
}

// ── Savings Tab ───────────────────────────────────────────────────────────────

class _SavingsTab extends StatelessWidget {
  final SavingsController controller;
  final bool isDark;

  const _SavingsTab({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.goals.isEmpty) {
        return _EmptyView(
          icon: PhosphorIconsLight.currencyCircleDollar,
          title: 'No savings goals yet',
          subtitle:
              'Create a goal, set a target amount, and track your\nprogress as you save.',
          cta: 'Tap + to add a goal · Swipe left to delete',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      }

      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.fetchGoals,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppDimens.spaceLG)
                    .copyWith(bottom: AppDimens.spaceMD),
                itemCount: controller.goals.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimens.spaceMD),
                itemBuilder: (_, index) {
                  final goal = controller.goals[index];
                  return _SavingsGoalCard(
                    goal: goal,
                    controller: controller,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onAddMoney: () =>
                        _showAddMoneySheet(context, controller, goal),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.spaceLG, 0, AppDimens.spaceLG, AppDimens.spaceLG),
            child: Text(
              'Swipe left on a card to delete a savings goal.',
              style: AppTypography.caption(isDark
                  ? AppColor.textTertiary
                  : AppColor.lightTextTertiary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 80),
        ],
      );
    });
  }

  void _showAddMoneySheet(
      BuildContext ctx, SavingsController controller, SavingsGoal goal) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMoneySheet(controller: controller, goal: goal),
    );
  }
}

// ── Savings Goal Card ─────────────────────────────────────────────────────────

class _SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final SavingsController controller;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onAddMoney;

  const _SavingsGoalCard({
    required this.goal,
    required this.controller,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onAddMoney,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = goal.savedAmount >= goal.targetAmount;
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final barColor = isComplete ? AppColor.income : AppColor.primary;

    // Days remaining calculation
    String? daysLabel;
    if (goal.targetDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadline = DateTime(goal.targetDate!.year, goal.targetDate!.month, goal.targetDate!.day);
      final days = deadline.difference(today).inDays;
      daysLabel = days < 0
          ? 'Past due'
          : days == 0
              ? 'Due today'
              : days == 1
                  ? 'Due tomorrow'
                  : '$days days left';
    }

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.spaceLG),
        decoration: BoxDecoration(
          color: AppColor.expense.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        ),
        child: const PhosphorIcon(PhosphorIconsLight.trash,
            color: AppColor.expense),
      ),
      onDismissed: (_) => controller.deleteGoal(goal.id),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spaceXL),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(goal.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: AppDimens.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name,
                          style: AppTypography.bodySemiBold(textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (daysLabel != null)
                        Text(daysLabel,
                            style: AppTypography.caption(textSecondary)),
                    ],
                  ),
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.spaceMD,
                        vertical: AppDimens.spaceXXS + 2),
                    decoration: BoxDecoration(
                      color: AppColor.income.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusCircle),
                    ),
                    child: Text('Achieved! 🎉',
                        style: AppTypography.captionSemiBold(AppColor.income)),
                  ),
              ],
            ),
            const SizedBox(height: AppDimens.spaceXL),

            // Amount row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${Get.find<HomeController>().currencySymbol.value}${fmt.format(goal.savedAmount)} saved',
                    style: AppTypography.bodySemiBoldTabular(textPrimary)),
                Text(
                    'of ${Get.find<HomeController>().currencySymbol.value}${fmt.format(goal.targetAmount)}',
                    style: AppTypography.caption(textSecondary)),
              ],
            ),
            const SizedBox(height: AppDimens.spaceMD),

            // Progress bar
            LayoutBuilder(builder: (context, constraints) {
              return Stack(children: [
                Container(
                  height: 8,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 8,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                  ),
                ),
              ]);
            }),
            const SizedBox(height: AppDimens.spaceSM),

            // Footer row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% funded',
                  style: AppTypography.caption(textSecondary),
                ),
                if (!isComplete)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onAddMoney();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.spaceMD,
                          vertical: AppDimens.spaceXS),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusCircle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PhosphorIcon(PhosphorIconsLight.plus,
                              size: 14, color: AppColor.primary),
                          const SizedBox(width: 4),
                          Text('Add money',
                              style: AppTypography.captionSemiBold(
                                  AppColor.primary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared empty state ────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final PhosphorIconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final Color textPrimary;
  final Color textSecondary;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceXXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColor.primaryGlow,
                borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
              ),
              child: PhosphorIcon(icon,
                  color: AppColor.primary, size: AppDimens.iconHero),
            ),
            const SizedBox(height: AppDimens.spaceXXL),
            Text(title, style: AppTypography.heading3(textPrimary)),
            const SizedBox(height: AppDimens.spaceSM),
            Text(subtitle,
                style: AppTypography.body(textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.spaceSM),
            Text(cta,
                style: AppTypography.captionSemiBold(AppColor.primary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Add Budget Sheet ──────────────────────────────────────────────────────────

class _AddBudgetSheet extends StatefulWidget {
  final GoalsController controller;

  const _AddBudgetSheet({required this.controller});

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _amountController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedPeriod = 'monthly';
  bool _isSaving = false;

  List<String> get _categories {
    final homeC = Get.find<HomeController>();
    final fromTx = homeC.transactions
        .map((t) => t['category'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toSet();
    final predefined = categoryList.map((c) => c.name).toSet();
    final all = {...predefined, ...fromTx}.toList()..sort();
    return ['All', ...all];
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _isSaving = true);
    await widget.controller.addGoal(
      category: _selectedCategory,
      limitAmount: amount,
      period: _selectedPeriod,
    );
    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final chipBg = isDark ? AppColor.darkCard : AppColor.lightBg;

    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXXXL)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDimens.spaceXXL,
          AppDimens.spaceXXL,
          AppDimens.spaceXXL,
          AppDimens.spaceXXL + keyboardH,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spaceXXL),
            Text('Set budget limit',
                style: AppTypography.heading2(textPrimary)),
            const SizedBox(height: AppDimens.spaceXXL),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Limit amount',
                prefixIcon: Align(
                  widthFactor: 1.0,
                  child: Text(
                    Get.find<HomeController>().currencySymbol.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColor.textSecondary
                          : AppColor.lightTextSecondary,
                    ),
                  ),
                ),
                hintText: 'e.g. 5000',
              ),
            ),
            const SizedBox(height: AppDimens.spaceXL),
            Text('Period', style: AppTypography.bodySemiBold(textPrimary)),
            const SizedBox(height: AppDimens.spaceSM),
            Row(
              children: ['monthly', 'weekly'].map((p) {
                final isSelected = _selectedPeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimens.spaceSM),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.spaceLG,
                          vertical: AppDimens.spaceSM),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColor.primary : chipBg,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                        border: Border.all(
                          color: isSelected
                              ? AppColor.primary
                              : (isDark
                                  ? AppColor.darkBorder
                                  : AppColor.lightBorder),
                        ),
                      ),
                      child: Text(
                        '${p[0].toUpperCase()}${p.substring(1)}',
                        style: AppTypography.bodySemiBold(
                          isSelected ? Colors.white : textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.spaceXL),
            Text('Category', style: AppTypography.bodySemiBold(textPrimary)),
            const SizedBox(height: AppDimens.spaceSM),
            Wrap(
              spacing: AppDimens.spaceSM,
              runSpacing: AppDimens.spaceSM,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                final catColor = AppColor.categoryColor(cat);
                final catEntry = categoryList.firstWhere(
                  (c) => c.name == cat,
                  orElse: () => CategoriesModel(name: cat, icon: PhosphorIconsLight.tag),
                );
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? catColor.withValues(alpha: 0.10)
                          : chipBg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? catColor
                            : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: PhosphorIcon(
                              catEntry.icon as PhosphorIconData,
                              color: catColor,
                              size: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.split(' ').first,
                          style: AppTypography.body(
                            isSelected ? catColor : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.spaceXXXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save limit'),
              ),
            ),
            const SizedBox(height: AppDimens.spaceMD),
          ],
        ),
      ),
    );
  }
}

// ── Add Savings Goal Sheet ────────────────────────────────────────────────────

class _AddSavingsSheet extends StatefulWidget {
  final SavingsController controller;

  const _AddSavingsSheet({required this.controller});

  @override
  State<_AddSavingsSheet> createState() => _AddSavingsSheetState();
}

class _AddSavingsSheetState extends State<_AddSavingsSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedEmoji = '🎯';
  DateTime? _targetDate;
  bool _isSaving = false;

  static const _emojis = [
    '🎯',
    '🏖️',
    '✈️',
    '🚗',
    '🏠',
    '💍',
    '📱',
    '🎓',
    '🏋️',
    '💊',
    '🛍️',
    '🍕',
    '🎮',
    '🎸',
    '🐶',
    '🌱',
    '📷',
    '🎁',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a goal name')));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid target amount')));
      return;
    }
    setState(() => _isSaving = true);
    await widget.controller.addGoal(
      name: name,
      targetAmount: amount,
      emoji: _selectedEmoji,
      targetDate: _targetDate,
    );
    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXXXL)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDimens.spaceXXL,
          AppDimens.spaceXXL,
          AppDimens.spaceXXL,
          AppDimens.spaceXXL + keyboardH,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spaceXXL),
            Text('New savings goal',
                style: AppTypography.heading2(textPrimary)),
            const SizedBox(height: AppDimens.spaceXXL),

            // Emoji picker
            Text('Icon', style: AppTypography.bodySemiBold(textPrimary)),
            const SizedBox(height: AppDimens.spaceSM),
            Wrap(
              spacing: AppDimens.spaceSM,
              runSpacing: AppDimens.spaceSM,
              children: _emojis.map((e) {
                final isSelected = _selectedEmoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColor.primary.withValues(alpha: 0.12)
                          : (isDark ? AppColor.darkCard : AppColor.lightBg),
                      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                      border: Border.all(
                        color:
                            isSelected ? AppColor.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.spaceXL),

            // Goal name
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Goal name',
                hintText: 'e.g. Vacation to Bali',
                prefixIcon: PhosphorIcon(PhosphorIconsLight.pencilSimple),
              ),
            ),
            const SizedBox(height: AppDimens.spaceMD),

            // Target amount
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target amount',
                hintText: 'e.g. 50000',
                prefixIcon: Align(
                  widthFactor: 1.0,
                  child: Text(
                    Get.find<HomeController>().currencySymbol.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColor.textSecondary
                          : AppColor.lightTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spaceMD),

            // Target date (optional)
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spaceLG, vertical: AppDimens.spaceMD),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkSurface : AppColor.lightSurface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                  border: Border.all(
                    color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    PhosphorIcon(PhosphorIconsLight.calendar,
                        color: textSecondary, size: AppDimens.iconMD),
                    const SizedBox(width: AppDimens.spaceMD),
                    Text(
                      _targetDate == null
                          ? 'Target date (optional)'
                          : DateFormat('d MMM yyyy').format(_targetDate!),
                      style: AppTypography.body(
                        _targetDate == null
                            ? (isDark
                                ? AppColor.textTertiary
                                : AppColor.lightTextTertiary)
                            : textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
                        child: PhosphorIcon(PhosphorIconsLight.x,
                            size: AppDimens.iconSM, color: textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spaceXXXL),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create goal'),
              ),
            ),
            const SizedBox(height: AppDimens.spaceMD),
          ],
        ),
      ),
    );
  }
}

// ── Bills Tab ─────────────────────────────────────────────────────────────────

class _BillsTab extends StatelessWidget {
  final RecurringBillsController controller;
  final bool isDark;

  const _BillsTab({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final hasSuggestions = controller.suggestions.isNotEmpty;
      final hasBills = controller.bills.isNotEmpty;

      if (!hasSuggestions && !hasBills) {
        return _EmptyView(
          icon: PhosphorIconsLight.calendarCheck,
          title: 'No recurring bills yet',
          subtitle:
              'Spendify will automatically detect subscriptions and regular payments as you add more transactions.',
          cta: 'Tap + to add a bill manually',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchBills,
        child: ListView(
          padding: const EdgeInsets.only(
              left: AppDimens.spaceLG,
              right: AppDimens.spaceLG,
              top: AppDimens.spaceLG,
              bottom: 100),
          children: [
            if (hasSuggestions) ...[
              _SectionHeader(
                title: 'We noticed these',
                subtitle: 'Confirm to start tracking & get reminders',
                isDark: isDark,
              ),
              const SizedBox(height: AppDimens.spaceMD),
              ...controller.suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.spaceMD),
                    child: _SuggestionCard(
                      suggestion: s,
                      controller: controller,
                      isDark: isDark,
                    ),
                  )),
              if (hasBills) const SizedBox(height: AppDimens.spaceXL),
            ],
            if (hasBills) ...[
              _SectionHeader(
                title: 'Tracked bills',
                subtitle: 'Swipe left to remove',
                isDark: isDark,
              ),
              const SizedBox(height: AppDimens.spaceMD),
              ...controller.bills.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.spaceMD),
                    child: _BillCard(
                      bill: b,
                      controller: controller,
                      isDark: isDark,
                    ),
                  )),
            ],
          ],
        ),
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.bodySemiBold(textPrimary)),
        Text(subtitle, style: AppTypography.caption(textSecondary)),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final RecurringBillSuggestion suggestion;
  final RecurringBillsController controller;
  final bool isDark;

  const _SuggestionCard({
    required this.suggestion,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppDimens.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                ),
                child: const Center(
                  child: PhosphorIcon(PhosphorIconsLight.sparkle,
                      color: AppColor.primary, size: 20),
                ),
              ),
              const SizedBox(width: AppDimens.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion.merchantName,
                        style: AppTypography.bodySemiBold(textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '$sym${fmt.format(suggestion.avgAmount)} · ${suggestion.frequency} · ${suggestion.occurrences}x detected',
                      style: AppTypography.caption(textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceMD),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.dismissSuggestion(suggestion),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSecondary,
                    side: BorderSide(color: border),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppDimens.spaceSM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                    ),
                  ),
                  child: Text('Dismiss',
                      style: AppTypography.body(textSecondary)),
                ),
              ),
              const SizedBox(width: AppDimens.spaceMD),
              Expanded(
                child: FilledButton(
                  onPressed: () => controller.confirmSuggestion(suggestion),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppDimens.spaceSM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                    ),
                  ),
                  child: Text('Track this',
                      style: AppTypography.bodySemiBold(Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final RecurringBill bill;
  final RecurringBillsController controller;
  final bool isDark;

  const _BillCard({
    required this.bill,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0', 'en_IN');

    Color statusColor;
    if (bill.isPaidThisCycle) {
      statusColor = AppColor.income;
    } else if (bill.isOverdue) {
      statusColor = AppColor.expense;
    } else if (bill.isUrgent) {
      statusColor = AppColor.warning;
    } else {
      statusColor = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    }

    return Dismissible(
      key: Key(bill.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.spaceLG),
        decoration: BoxDecoration(
          color: AppColor.expense.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        ),
        child:
            const PhosphorIcon(PhosphorIconsLight.trash, color: AppColor.expense),
      ),
      onDismissed: (_) => controller.deleteBill(bill.id),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(AppDimens.spaceLG),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
              ),
              child: Center(
                child: PhosphorIcon(_billIcon(bill.merchantName),
                    color: statusColor, size: 20),
              ),
            ),
            const SizedBox(width: AppDimens.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.merchantName,
                      style: AppTypography.bodySemiBold(textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '$sym${fmt.format(bill.amount)} · ${bill.frequency}',
                    style: AppTypography.caption(textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spaceMD, vertical: AppDimens.spaceXXS + 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
              ),
              child: Text(bill.statusLabel,
                  style: AppTypography.captionSemiBold(statusColor)),
            ),
          ],
        ),
      ),
    );
  }

  PhosphorIconData _billIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('jio') || n.contains('airtel') || n.contains('vi') || n.contains('bsnl')) {
      return PhosphorIconsLight.simCard;
    }
    if (n.contains('netflix') || n.contains('hotstar') || n.contains('spotify') ||
        n.contains('prime') || n.contains('youtube')) {
      return PhosphorIconsLight.television;
    }
    if (n.contains('electricity') || n.contains('water') || n.contains('gas')) {
      return PhosphorIconsLight.lightningA;
    }
    if (n.contains('rent') || n.contains('maintenance')) {
      return PhosphorIconsLight.houseSimple;
    }
    if (n.contains('gym') || n.contains('fitness')) {
      return PhosphorIconsLight.barbell;
    }
    if (n.contains('emi') || n.contains('loan')) {
      return PhosphorIconsLight.bank;
    }
    return PhosphorIconsLight.calendarCheck;
  }
}

// ── Add Bill Sheet (manual entry) ─────────────────────────────────────────────

class _AddBillSheet extends StatefulWidget {
  final RecurringBillsController controller;

  const _AddBillSheet({required this.controller});

  @override
  State<_AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends State<_AddBillSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _frequency = 'monthly';
  int _dueDay = 1;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a bill name')));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _isSaving = true);
    await widget.controller.addBillManually(
      merchantName: name,
      amount: amount,
      frequency: _frequency,
      dueDay: _dueDay,
    );
    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final chipBg = isDark ? AppColor.darkCard : AppColor.lightBg;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXXXL)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(AppDimens.spaceXXL, AppDimens.spaceXXL,
            AppDimens.spaceXXL, AppDimens.spaceXXL + keyboardH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spaceXXL),
            Text('Add recurring bill',
                style: AppTypography.heading2(textPrimary)),
            const SizedBox(height: AppDimens.spaceXXL),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Bill name',
                hintText: 'e.g. Netflix, Jio, Rent',
                prefixIcon: PhosphorIcon(PhosphorIconsLight.tag),
              ),
            ),
            const SizedBox(height: AppDimens.spaceMD),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g. 649',
                prefixIcon: Align(
                  widthFactor: 1.0,
                  child: Text(
                    Get.find<HomeController>().currencySymbol.value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spaceXL),
            Text('Frequency', style: AppTypography.bodySemiBold(textPrimary)),
            const SizedBox(height: AppDimens.spaceSM),
            Row(
              children: ['monthly', 'quarterly', 'yearly'].map((f) {
                final selected = _frequency == f;
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimens.spaceSM),
                  child: GestureDetector(
                    onTap: () => setState(() => _frequency = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.spaceLG,
                          vertical: AppDimens.spaceSM),
                      decoration: BoxDecoration(
                        color: selected ? AppColor.primary : chipBg,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                        border: Border.all(
                          color: selected
                              ? AppColor.primary
                              : (isDark
                                  ? AppColor.darkBorder
                                  : AppColor.lightBorder),
                        ),
                      ),
                      child: Text(
                        '${f[0].toUpperCase()}${f.substring(1)}',
                        style: AppTypography.bodySemiBold(
                            selected ? Colors.white : textSecondary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.spaceXL),
            Text('Due day of month',
                style: AppTypography.bodySemiBold(textPrimary)),
            const SizedBox(height: AppDimens.spaceSM),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _dueDay.toDouble(),
                    min: 1,
                    max: 28,
                    divisions: 27,
                    label: '$_dueDay',
                    activeColor: AppColor.primary,
                    onChanged: (v) => setState(() => _dueDay = v.round()),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$_dueDay',
                    style: AppTypography.bodySemiBold(textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spaceXXXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add bill'),
              ),
            ),
            const SizedBox(height: AppDimens.spaceMD),
          ],
        ),
      ),
    );
  }
}

// ── Add Money Sheet ───────────────────────────────────────────────────────────

class _AddMoneySheet extends StatefulWidget {
  final SavingsController controller;
  final SavingsGoal goal;

  const _AddMoneySheet({required this.controller, required this.goal});

  @override
  State<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends State<_AddMoneySheet> {
  final _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _isSaving = true);
    await widget.controller.addSavings(widget.goal.id, amount);
    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final fmt = NumberFormat('#,##0', 'en_IN');
    final remaining = widget.goal.targetAmount - widget.goal.savedAmount;

    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXXXL)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDimens.spaceXXL,
          AppDimens.spaceXXL,
          AppDimens.spaceXXL,
          AppDimens.spaceXXL + keyboardH,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spaceXXL),
            Row(
              children: [
                Text(widget.goal.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: AppDimens.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.goal.name,
                          style: AppTypography.heading2(textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${Get.find<HomeController>().currencySymbol.value}${fmt.format(remaining)} still needed',
                        style: AppTypography.caption(textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spaceXXL),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText:
                    'Amount to add (${Get.find<HomeController>().currencySymbol.value})',
                prefixText: Get.find<HomeController>().currencySymbol.value,
                hintText: 'e.g. 1000',
              ),
            ),
            const SizedBox(height: AppDimens.spaceXXXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add to savings'),
              ),
            ),
            const SizedBox(height: AppDimens.spaceMD),
          ],
        ),
      ),
    );
  }
}
