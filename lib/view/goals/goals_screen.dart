import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
// GOALS SCREEN  –  Budget · Savings · Subscriptions
// Light mode only — no isDark conditionals anywhere.
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
    final spendingC = Get.find<GoalsController>();
    final savingsC = Get.find<SavingsController>();
    final billsC = Get.find<RecurringBillsController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Goals', style: AppTypography.heading2(AppColor.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColor.primary,
          indicatorWeight: 2,
          labelColor: AppColor.primary,
          unselectedLabelColor: AppColor.textSecondary,
          labelStyle: AppTypography.bodySemiBold(AppColor.primary),
          unselectedLabelStyle: AppTypography.body(AppColor.textSecondary),
          dividerColor: AppColor.border,
          tabs: const [
            Tab(text: 'Budget'),
            Tab(text: 'Savings'),
            Tab(text: 'Subscriptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BudgetTab(controller: spendingC),
          _SavingsTab(controller: savingsC),
          _BillsTab(controller: billsC),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point called from BottomNav's universal + button.
// ─────────────────────────────────────────────────────────────────────────────

void showGoalsAddPicker(BuildContext ctx) {
  final spendingC = Get.find<GoalsController>();
  final savingsC = Get.find<SavingsController>();
  final billsC = Get.find<RecurringBillsController>();

  showModalBottomSheet(
    context: ctx,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColor.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('What would you like to add?',
              style: AppTypography.bodySemiBold(AppColor.textPrimary)),
          const SizedBox(height: 16),
          _PickerOption(
            icon: PhosphorIconsLight.chartPieSlice,
            label: 'Budget Limit',
            subtitle: 'Set a spending cap for a category',
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
            label: 'Subscription',
            subtitle: 'Track a subscription or recurring payment',
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
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColor.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.bodySemiBold(AppColor.textPrimary)),
                  Text(subtitle, style: AppTypography.caption(AppColor.textSecondary)),
                ],
              ),
            ),
            PhosphorIcon(PhosphorIconsLight.caretRight, color: AppColor.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUDGET TAB
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetTab extends StatelessWidget {
  final GoalsController controller;

  const _BudgetTab({required this.controller});

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
    final hc = Get.find<HomeController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColor.primary));
      }

      final monthlyBudget = hc.monthlyBudget.value;
      final hasMonthlyBudget = monthlyBudget > 0;
      final hasGoals = controller.goals.isNotEmpty;

      if (!hasMonthlyBudget && !hasGoals) {
        return const _EmptyView(
          icon: PhosphorIconsLight.wallet,
          title: 'No budget set yet',
          subtitle: 'Set a monthly budget in your preferences, or add category spending limits here.',
          cta: 'Tap + to add a limit · Swipe left to delete',
        );
      }

      double totalLimit = 0;
      double totalSpent = 0;
      for (final g in controller.goals) {
        totalLimit += g.limitAmount;
        totalSpent += controller.currentSpending(g);
      }
      final totalProgress = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
      final monthExpense = _thisMonthExpense(hc);

      return RefreshIndicator(
        onRefresh: controller.fetchGoals,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            if (hasMonthlyBudget)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _MonthlyBudgetCard(budget: monthlyBudget, spent: monthExpense),
              ),
            if (hasGoals) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: _BudgetSummaryCard(
                  totalLimit: totalLimit,
                  totalSpent: totalSpent,
                  totalProgress: totalProgress,
                ),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.border),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < controller.goals.length; i++) ...[
                      _BudgetRow(goal: controller.goals[i], controller: controller),
                      if (i < controller.goals.length - 1)
                        const Divider(height: 1, thickness: 1, color: AppColor.border, indent: 68, endIndent: 16),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Swipe left on a row to delete a budget limit.',
                  style: AppTypography.caption(AppColor.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else if (hasMonthlyBudget) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tap + to add category spending limits.',
                  style: AppTypography.caption(AppColor.textTertiary),
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

class _BudgetSummaryCard extends StatelessWidget {
  final double totalLimit;
  final double totalSpent;
  final double totalProgress;

  const _BudgetSummaryCard({
    required this.totalLimit,
    required this.totalSpent,
    required this.totalProgress,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final sym = Get.find<HomeController>().currencySymbol.value;
    final remaining = totalLimit - totalSpent;
    final isOver = remaining < 0;
    final barColor = totalProgress >= 1.0
        ? AppColor.expense
        : totalProgress >= 0.8
            ? AppColor.warning
            : AppColor.income;
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(PhosphorIconsLight.calendar, color: AppColor.textTertiary, size: 14),
              const SizedBox(width: 6),
              Text(monthName, style: AppTypography.caption(AppColor.textTertiary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SummaryCol(label: 'Budgeted', value: '$sym${fmt.format(totalLimit)}', color: AppColor.textPrimary)),
              Expanded(child: _SummaryCol(label: 'Spent', value: '$sym${fmt.format(totalSpent)}', color: AppColor.textPrimary)),
              Expanded(child: _SummaryCol(
                label: isOver ? 'Over by' : 'Remaining',
                value: '$sym${fmt.format(remaining.abs())}',
                color: isOver ? AppColor.expense : AppColor.income,
              )),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: totalProgress,
              minHeight: 5,
              backgroundColor: barColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(totalProgress * 100).toStringAsFixed(0)}% of total budget used',
            style: AppTypography.label(AppColor.textTertiary),
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

  const _SummaryCol({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label(color.withValues(alpha: 0.5))),
          const SizedBox(height: 2),
          Text(value,
              style: AppTypography.bodySemiBold(color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      );
}

class _MonthlyBudgetCard extends StatelessWidget {
  final double budget;
  final double spent;

  const _MonthlyBudgetCard({required this.budget, required this.spent});

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
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const PhosphorIcon(PhosphorIconsLight.wallet, color: AppColor.primary, size: 14),
              ),
              const SizedBox(width: 8),
              Text('Monthly Budget', style: AppTypography.bodySemiBold(AppColor.textPrimary)),
              const Spacer(),
              Text(monthName, style: AppTypography.caption(AppColor.textTertiary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SummaryCol(label: 'Budget', value: '$sym${fmt.format(budget)}', color: AppColor.textPrimary)),
              Expanded(child: _SummaryCol(label: 'Spent', value: '$sym${fmt.format(spent)}', color: AppColor.textPrimary)),
              Expanded(child: _SummaryCol(
                label: isOver ? 'Over by' : 'Remaining',
                value: '$sym${fmt.format(remaining.abs())}',
                color: isOver ? AppColor.expense : AppColor.income,
              )),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: barColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% of monthly budget used',
            style: AppTypography.label(AppColor.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final SpendingGoal goal;
  final GoalsController controller;

  const _BudgetRow({required this.goal, required this.controller});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final sym = Get.find<HomeController>().currencySymbol.value;
    final spent = controller.currentSpending(goal);
    final progress = goal.limitAmount > 0 ? (spent / goal.limitAmount).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > goal.limitAmount;
    final isNear = !isOver && progress >= 0.8;
    final barColor = isOver ? AppColor.expense : isNear ? AppColor.warning : AppColor.income;

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColor.expense.withValues(alpha: 0.08),
        child: const PhosphorIcon(PhosphorIconsLight.trash, color: AppColor.expense),
      ),
      onDismissed: (_) => controller.deleteGoal(goal.id),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EEF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: PhosphorIcon(_categoryIcon(goal.category), color: AppColor.textSecondary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.category == 'All' ? 'Total Spending' : goal.category,
                          style: AppTypography.bodySemiBold(AppColor.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$sym${fmt.format(spent)} / $sym${fmt.format(goal.limitAmount)}',
                        style: AppTypography.caption(isOver ? AppColor.expense : AppColor.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(builder: (_, constraints) {
                    return Stack(children: [
                      Container(
                        height: 4,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        height: 4,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ]);
                  }),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% used'
                    '${isOver ? ' · Over limit' : isNear ? ' · Near limit' : ''}',
                    style: AppTypography.label(isOver ? AppColor.expense : isNear ? AppColor.warning : AppColor.textTertiary),
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
    if (k.contains('health') || k.contains('medical')) return PhosphorIconsLight.heart;
    if (k.contains('bill') || k.contains('fee')) return PhosphorIconsLight.receipt;
    if (k.contains('food') || k.contains('drink')) return PhosphorIconsLight.coffee;
    if (k.contains('car') || k.contains('vehicle')) return PhosphorIconsLight.car;
    if (k.contains('grocer')) return PhosphorIconsLight.shoppingCart;
    if (k.contains('gift')) return PhosphorIconsLight.gift;
    if (k.contains('transport')) return PhosphorIconsLight.bus;
    return PhosphorIconsLight.squaresFour;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVINGS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _SavingsTab extends StatelessWidget {
  final SavingsController controller;

  const _SavingsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColor.primary));
      }

      if (controller.goals.isEmpty) {
        return const _EmptyView(
          icon: PhosphorIconsLight.currencyCircleDollar,
          title: 'No savings goals yet',
          subtitle: 'Create a goal, set a target amount, and track your\nprogress as you save.',
          cta: 'Tap + to add a goal · Swipe left to delete',
        );
      }

      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.fetchGoals,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                itemCount: controller.goals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final goal = controller.goals[index];
                  return _SavingsGoalCard(
                    goal: goal,
                    controller: controller,
                    onAddMoney: () => _showAddMoneySheet(context, controller, goal),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Swipe left on a card to delete a savings goal.',
              style: AppTypography.caption(AppColor.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 80),
        ],
      );
    });
  }

  void _showAddMoneySheet(BuildContext ctx, SavingsController ctrl, SavingsGoal goal) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMoneySheet(controller: ctrl, goal: goal),
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final SavingsController controller;
  final VoidCallback onAddMoney;

  const _SavingsGoalCard({
    required this.goal,
    required this.controller,
    required this.onAddMoney,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final sym = Get.find<HomeController>().currencySymbol.value;
    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = goal.savedAmount >= goal.targetAmount;
    final barColor = isComplete ? AppColor.income : AppColor.primary;

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
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColor.expense.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const PhosphorIcon(PhosphorIconsLight.trash, color: AppColor.expense),
      ),
      onDismissed: (_) => controller.deleteGoal(goal.id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name,
                          style: AppTypography.bodySemiBold(AppColor.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (daysLabel != null)
                        Text(daysLabel, style: AppTypography.caption(AppColor.textSecondary)),
                    ],
                  ),
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColor.income.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Achieved! 🎉', style: AppTypography.captionSemiBold(AppColor.income)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$sym${fmt.format(goal.savedAmount)} saved',
                    style: AppTypography.bodySemiBoldTabular(AppColor.textPrimary)),
                Text('of $sym${fmt.format(goal.targetAmount)}',
                    style: AppTypography.caption(AppColor.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (_, constraints) {
              return Stack(children: [
                Container(
                  height: 8,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 8,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ]);
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toStringAsFixed(0)}% funded',
                    style: AppTypography.caption(AppColor.textSecondary)),
                if (!isComplete)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onAddMoney();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PhosphorIcon(PhosphorIconsLight.plus, size: 13, color: AppColor.primary),
                          const SizedBox(width: 4),
                          Text('Add money', style: AppTypography.captionSemiBold(AppColor.primary)),
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

// ─────────────────────────────────────────────────────────────────────────────
// SUBSCRIPTIONS TAB  –  Calendar view
// ─────────────────────────────────────────────────────────────────────────────

class _BillsTab extends StatefulWidget {
  final RecurringBillsController controller;

  const _BillsTab({required this.controller});

  @override
  State<_BillsTab> createState() => _BillsTabState();
}

class _BillsTabState extends State<_BillsTab> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
  }

  bool _billDueThisMonth(RecurringBill bill) {
    switch (bill.frequency) {
      case 'yearly':
        return bill.createdAt.month == _viewMonth.month;
      case 'quarterly':
        final diff = (_viewMonth.month - bill.createdAt.month) % 3;
        return diff == 0;
      default:
        return true; // monthly always shows
    }
  }

  List<RecurringBill> _billsForDay(int day) {
    return widget.controller.bills
        .where((b) => b.dueDay == day && _billDueThisMonth(b))
        .toList();
  }

  double _monthTotal() {
    return widget.controller.bills
        .where(_billDueThisMonth)
        .fold(0.0, (s, b) => s + b.amount);
  }

  void _prevMonth() {
    HapticFeedback.lightImpact();
    setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_viewMonth.year == now.year && _viewMonth.month == now.month) return;
    HapticFeedback.lightImpact();
    setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));
  }

  void _showDaySheet(BuildContext ctx, int day, List<RecurringBill> bills) {
    if (bills.isEmpty) return;
    final date = DateTime(_viewMonth.year, _viewMonth.month, day);
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DayBillsSheet(
        date: date,
        bills: bills,
        controller: widget.controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColor.primary));
      }

      final hasSuggestions = widget.controller.suggestions.isNotEmpty;
      final hasBills = widget.controller.bills.isNotEmpty;

      if (!hasSuggestions && !hasBills) {
        return const _EmptyView(
          icon: PhosphorIconsLight.calendarCheck,
          title: 'No subscriptions yet',
          subtitle: 'Spendify detects recurring payments automatically as you add transactions.',
          cta: 'Tap + to add a subscription manually',
        );
      }

      final sym = Get.find<HomeController>().currencySymbol.value;
      final fmt = NumberFormat('#,##0.##', 'en_IN');
      final monthTotal = _monthTotal();
      final now = DateTime.now();
      final isCurrentMonth = _viewMonth.year == now.year && _viewMonth.month == now.month;
      final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
      final firstWeekday = DateTime(_viewMonth.year, _viewMonth.month, 1).weekday; // 1=Mon

      return RefreshIndicator(
        onRefresh: widget.controller.fetchBills,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // ── Month header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const PhosphorIcon(PhosphorIconsLight.caretLeft, size: 18),
                    color: AppColor.textSecondary,
                    onPressed: _prevMonth,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMMM').format(_viewMonth),
                          style: GoogleFonts.urbanist(
                            fontSize: 12, color: AppColor.textTertiary,
                            fontWeight: FontWeight.w500, letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$sym${fmt.format(monthTotal)}',
                          style: GoogleFonts.urbanist(
                            fontSize: 30, fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColor.income.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Regular Month',
                            style: GoogleFonts.urbanist(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: AppColor.income,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: PhosphorIcon(
                      PhosphorIconsLight.caretRight, size: 18,
                      color: isCurrentMonth ? Colors.transparent : AppColor.textSecondary,
                    ),
                    onPressed: isCurrentMonth ? null : _nextMonth,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Day-of-week headers ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.urbanist(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppColor.textTertiary, letterSpacing: 0.3,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 4),

            // ── Calendar grid ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _CalendarGrid(
                viewMonth: _viewMonth,
                firstWeekday: firstWeekday,
                daysInMonth: daysInMonth,
                today: now,
                billsForDay: _billsForDay,
                onDayTap: (day, bills) => _showDaySheet(context, day, bills),
              ),
            ),

            // ── Auto-detected suggestions ─────────────────────────────────
            if (hasSuggestions) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Divider(color: AppColor.border, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('DETECTED', style: GoogleFonts.urbanist(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColor.textTertiary, letterSpacing: 0.8,
                )),
              ),
              ...widget.controller.suggestions.map((s) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _SuggestionCard(suggestion: s, controller: widget.controller),
              )),
            ],

            // ── All subscriptions list ────────────────────────────────────
            if (hasBills) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Divider(color: AppColor.border, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('ALL SUBSCRIPTIONS', style: GoogleFonts.urbanist(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColor.textTertiary, letterSpacing: 0.8,
                )),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.border),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < widget.controller.bills.length; i++) ...[
                      _BillListRow(
                        bill: widget.controller.bills[i],
                        controller: widget.controller,
                        sym: sym,
                        fmt: NumberFormat('#,##0', 'en_IN'),
                      ),
                      if (i < widget.controller.bills.length - 1)
                        const Divider(height: 1, color: AppColor.border, indent: 64, endIndent: 16),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Calendar grid ─────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime viewMonth;
  final int firstWeekday;
  final int daysInMonth;
  final DateTime today;
  final List<RecurringBill> Function(int day) billsForDay;
  final void Function(int day, List<RecurringBill> bills) onDayTap;

  const _CalendarGrid({
    required this.viewMonth,
    required this.firstWeekday,
    required this.daysInMonth,
    required this.today,
    required this.billsForDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final offset = firstWeekday - 1; // Mon=0 offset
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final day = cellIndex - offset + 1;
            if (day < 1 || day > daysInMonth) {
              return const Expanded(child: _EmptyCell());
            }
            final bills = billsForDay(day);
            final isToday = today.year == viewMonth.year &&
                today.month == viewMonth.month &&
                today.day == day;
            return Expanded(
              child: GestureDetector(
                onTap: bills.isNotEmpty ? () => onDayTap(day, bills) : null,
                child: _DayCell(day: day, bills: bills, isToday: isToday),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(3),
        child: AspectRatio(
          aspectRatio: 0.9,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}

class _DayCell extends StatelessWidget {
  final int day;
  final List<RecurringBill> bills;
  final bool isToday;

  const _DayCell({required this.day, required this.bills, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final hasBills = bills.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: AspectRatio(
        aspectRatio: 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: hasBills ? Colors.white : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: isToday
                ? Border.all(color: AppColor.primary, width: 2)
                : hasBills
                    ? Border.all(color: AppColor.border)
                    : null,
          ),
          child: Stack(
            children: [
              if (hasBills)
                Positioned(
                  top: 4, left: 0, right: 0, bottom: 16,
                  child: Center(child: _BillsWidget(bills: bills)),
                ),
              // "+N" badge when more than 2 subscriptions
              if (bills.length > 2)
                Positioned(
                  top: 3, right: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${bills.length - 2}',
                      style: GoogleFonts.urbanist(
                        fontSize: 6,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 4, left: 5,
                child: Text(
                  '$day',
                  style: GoogleFonts.urbanist(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: hasBills
                        ? (isToday ? AppColor.primary : AppColor.textSecondary)
                        : AppColor.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 1 bill → single 28px icon. 2+ bills → two 18px overlapping circles (second behind first).
class _BillsWidget extends StatelessWidget {
  final List<RecurringBill> bills;
  const _BillsWidget({required this.bills});

  @override
  Widget build(BuildContext context) {
    if (bills.length == 1) {
      return _ServiceDot(bill: bills[0], size: 28, radius: 8);
    }
    const dotSize = 18.0;
    const shift = 10.0; // how far the second icon peeks out
    return SizedBox(
      width: dotSize + shift,
      height: dotSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Second icon (back) — slightly to the right, rendered first
          Positioned(
            left: shift,
            child: _RingDot(bill: bills[1], size: dotSize),
          ),
          // First icon (front) — on top at left: 0
          Positioned(
            left: 0,
            child: _RingDot(bill: bills[0], size: dotSize),
          ),
        ],
      ),
    );
  }
}

class _RingDot extends StatelessWidget {
  final RecurringBill bill;
  final double size;
  const _RingDot({required this.bill, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white, // white ring gap between overlapping icons
        ),
        padding: const EdgeInsets.all(1.5),
        child: _ServiceDot(bill: bill, size: size, radius: size / 2),
      );
}

// ── Service brand metadata ────────────────────────────────────────────────────
// slug = Simple Icons slug (https://simpleicons.org)
// bg   = brand background color
// Each entry keyed by lowercase keyword found in merchant name.

class _BrandMeta {
  final String slug;
  final Color bg;
  const _BrandMeta(this.slug, this.bg);
}

const _kBrandMap = <String, _BrandMeta>{
  'netflix':      _BrandMeta('netflix',        Color(0xFFE50914)),
  'spotify':      _BrandMeta('spotify',        Color(0xFF1DB954)),
  'youtube':      _BrandMeta('youtube',        Color(0xFFFF0000)),
  'prime video':  _BrandMeta('primevideo',     Color(0xFF00A8E0)),
  'amazon prime': _BrandMeta('primevideo',     Color(0xFF00A8E0)),
  'amazon':       _BrandMeta('amazon',         Color(0xFFFF9900)),
  'hotstar':      _BrandMeta('disneyplus',     Color(0xFF113CCF)),
  'disney':       _BrandMeta('disneyplus',     Color(0xFF113CCF)),
  'icloud':       _BrandMeta('icloud',         Color(0xFF3693F3)),
  'apple':        _BrandMeta('apple',          Color(0xFF555555)),
  'chatgpt':      _BrandMeta('openai',         Color(0xFF412991)),
  'openai':       _BrandMeta('openai',         Color(0xFF412991)),
  'linkedin':     _BrandMeta('linkedin',       Color(0xFF0077B5)),
  'microsoft':    _BrandMeta('microsoft',      Color(0xFF00BCF2)),
  'office 365':   _BrandMeta('microsoftoffice',Color(0xFFD83B01)),
  'adobe':        _BrandMeta('adobe',          Color(0xFFFF0000)),
  'notion':       _BrandMeta('notion',         Color(0xFF000000)),
  'github':       _BrandMeta('github',         Color(0xFF181717)),
  'figma':        _BrandMeta('figma',          Color(0xFF0ACF83)),
  'canva':        _BrandMeta('canva',          Color(0xFF00C4CC)),
  'dropbox':      _BrandMeta('dropbox',        Color(0xFF0061FF)),
  'slack':        _BrandMeta('slack',          Color(0xFF4A154B)),
  'google one':   _BrandMeta('google',         Color(0xFF4285F4)),
  'google':       _BrandMeta('google',         Color(0xFF4285F4)),
  'youtube premium': _BrandMeta('youtube',     Color(0xFFFF0000)),
  'zee5':         _BrandMeta('zee5',           Color(0xFF8B2FC9)),
  'sonyliv':      _BrandMeta('sony',           Color(0xFF000000)),
  'sony liv':     _BrandMeta('sony',           Color(0xFF000000)),
  'swiggy':       _BrandMeta('swiggy',         Color(0xFFFC8019)),
  'zomato':       _BrandMeta('zomato',         Color(0xFFE23744)),
  'jio':          _BrandMeta('jio',            Color(0xFF0055A5)),
  'airtel':       _BrandMeta('airtel',         Color(0xFFE40000)),
};

_BrandMeta? _brandFor(String name) {
  final n = name.toLowerCase();
  // Longest match first to avoid 'amazon' matching 'amazon prime'
  final sorted = _kBrandMap.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final key in sorted) {
    if (n.contains(key)) return _kBrandMap[key];
  }
  return null;
}

Color _hashColor(String name) {
  const palette = [
    Color(0xFF6B5BFF), Color(0xFF4BAFD6), Color(0xFFFF4081),
    Color(0xFF00C896), Color(0xFFF5A623), Color(0xFF7C3AED),
    Color(0xFF0891B2),
  ];
  return palette[name.length % palette.length];
}

// ── Service logo widget ───────────────────────────────────────────────────────

class _ServiceDot extends StatelessWidget {
  final RecurringBill bill;
  final double size;
  final double? radius;

  const _ServiceDot({required this.bill, this.size = 24, this.radius});

  @override
  Widget build(BuildContext context) {
    final meta = _brandFor(bill.merchantName);
    final br = radius ?? size * 0.28;
    final initial = bill.merchantName.isNotEmpty ? bill.merchantName[0].toUpperCase() : '?';
    final bg = meta?.bg ?? _hashColor(bill.merchantName);

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(br)),
      child: meta != null
          ? Padding(
              padding: EdgeInsets.all(size * 0.18),
              child: SvgPicture.network(
                'https://cdn.simpleicons.org/${meta.slug}/ffffff',
                fit: BoxFit.contain,
                placeholderBuilder: (_) => Center(
                  child: Text(initial,
                      style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                errorBuilder: (_, __, ___) => Center(
                  child: Text(initial,
                      style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            )
          : Center(
              child: Text(initial,
                  style: TextStyle(fontSize: size * 0.44, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
    );
  }
}

// ── Day bottom sheet (shown when tapping a calendar day) ─────────────────────

class _DayBillsSheet extends StatelessWidget {
  final DateTime date;
  final List<RecurringBill> bills;
  final RecurringBillsController controller;

  const _DayBillsSheet({
    required this.date,
    required this.bills,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0.##', 'en_IN');
    final total = bills.fold(0.0, (s, b) => s + b.amount);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 12, 24, MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColor.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('d MMMM yyyy').format(date),
            style: GoogleFonts.urbanist(fontSize: 13, color: AppColor.textTertiary),
          ),
          Text(
            'Subscriptions',
            style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
          ),
          const SizedBox(height: 16),

          // Bill rows
          ...bills.map((b) {
            Color statusColor;
            if (b.isPaidThisCycle) {
              statusColor = AppColor.income;
            } else if (b.isOverdue) {
              statusColor = AppColor.expense;
            } else {
              statusColor = AppColor.textSecondary;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _ServiceDot(bill: b, size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.merchantName,
                            style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                        Text(
                          '${b.frequency[0].toUpperCase()}${b.frequency.substring(1)}',
                          style: GoogleFonts.urbanist(fontSize: 12, color: AppColor.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sym${fmt.format(b.amount)}',
                        style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                      ),
                      Text(
                        b.statusLabel,
                        style: GoogleFonts.urbanist(fontSize: 11, color: statusColor),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Add subscription row
          InkWell(
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AddBillSheet(controller: controller),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EEF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: PhosphorIcon(PhosphorIconsLight.plus, size: 18, color: AppColor.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Add Subscription',
                      style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColor.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
              Text('$sym${fmt.format(total)}',
                  style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bill list row (compact, below the calendar) ───────────────────────────────

class _BillListRow extends StatelessWidget {
  final RecurringBill bill;
  final RecurringBillsController controller;
  final String sym;
  final NumberFormat fmt;

  const _BillListRow({
    required this.bill,
    required this.controller,
    required this.sym,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (bill.isPaidThisCycle) {
      statusColor = AppColor.income;
    } else if (bill.isOverdue) {
      statusColor = AppColor.expense;
    } else if (bill.isUrgent) {
      statusColor = AppColor.warning;
    } else {
      statusColor = AppColor.textSecondary;
    }

    return Dismissible(
      key: Key(bill.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF0F2),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: const PhosphorIcon(PhosphorIconsLight.trash, color: AppColor.expense),
      ),
      onDismissed: (_) => controller.deleteBill(bill.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _ServiceDot(bill: bill, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.merchantName,
                      style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${bill.frequency[0].toUpperCase()}${bill.frequency.substring(1)} · due ${bill.dueDay}${_daySuffix(bill.dueDay)}',
                    style: GoogleFonts.urbanist(fontSize: 12, color: AppColor.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sym${fmt.format(bill.amount)}',
                  style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(bill.statusLabel,
                      style: GoogleFonts.urbanist(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}

// ── Auto-detected suggestion card ─────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final RecurringBillSuggestion suggestion;
  final RecurringBillsController controller;

  const _SuggestionCard({required this.suggestion, required this.controller});

  @override
  Widget build(BuildContext context) {
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: PhosphorIcon(PhosphorIconsLight.sparkle, color: AppColor.primary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion.merchantName,
                        style: AppTypography.bodySemiBold(AppColor.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '$sym${fmt.format(suggestion.avgAmount)} · ${suggestion.frequency} · ${suggestion.occurrences}x detected',
                      style: AppTypography.caption(AppColor.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.dismissSuggestion(suggestion),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.textSecondary,
                    side: const BorderSide(color: AppColor.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Dismiss', style: AppTypography.body(AppColor.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => controller.confirmSuggestion(suggestion),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Track this', style: AppTypography.bodySemiBold(Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final PhosphorIconData icon;
  final String title;
  final String subtitle;
  final String cta;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: PhosphorIcon(icon, color: AppColor.primary, size: 32),
              ),
              const SizedBox(height: 20),
              Text(title, style: AppTypography.heading3(AppColor.textPrimary)),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: AppTypography.body(AppColor.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(cta,
                  style: AppTypography.captionSemiBold(AppColor.primary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD BUDGET SHEET
// ─────────────────────────────────────────────────────────────────────────────

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _isSaving = true);
    await widget.controller.addGoal(category: _selectedCategory, limitAmount: amount, period: _selectedPeriod);
    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColor.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Set budget limit', style: AppTypography.heading2(AppColor.textPrimary)),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Limit amount',
                prefixIcon: Align(
                  widthFactor: 1.0,
                  child: Text(
                    Get.find<HomeController>().currencySymbol.value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColor.textSecondary),
                  ),
                ),
                hintText: 'e.g. 5000',
              ),
            ),
            const SizedBox(height: 20),
            Text('Period', style: AppTypography.bodySemiBold(AppColor.textPrimary)),
            const SizedBox(height: 10),
            Row(
              children: ['monthly', 'weekly'].map((p) {
                final isSelected = _selectedPeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColor.primary : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppColor.primary : AppColor.border),
                      ),
                      child: Text(
                        '${p[0].toUpperCase()}${p.substring(1)}',
                        style: AppTypography.bodySemiBold(isSelected ? Colors.white : AppColor.textSecondary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Category', style: AppTypography.bodySemiBold(AppColor.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                      color: isSelected ? catColor.withValues(alpha: 0.10) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? catColor : AppColor.border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: PhosphorIcon(catEntry.icon as PhosphorIconData, color: catColor, size: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(cat.split(' ').first,
                            style: AppTypography.body(isSelected ? catColor : AppColor.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save limit'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD SAVINGS GOAL SHEET
// ─────────────────────────────────────────────────────────────────────────────

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
    '🎯','🏖️','✈️','🚗','🏠','💍','📱','🎓','🏋️','💊','🛍️','🍕','🎮','🎸','🐶','🌱','📷','🎁',
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a goal name')));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid target amount')));
      return;
    }
    setState(() => _isSaving = true);
    await widget.controller.addGoal(name: name, targetAmount: amount, emoji: _selectedEmoji, targetDate: _targetDate);
    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColor.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('New savings goal', style: AppTypography.heading2(AppColor.textPrimary)),
            const SizedBox(height: 24),
            Text('Icon', style: AppTypography.bodySemiBold(AppColor.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) {
                final isSelected = _selectedEmoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColor.primary.withValues(alpha: 0.10) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColor.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Goal name',
                hintText: 'e.g. Vacation to Bali',
                prefixIcon: PhosphorIcon(PhosphorIconsLight.pencilSimple),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target amount',
                hintText: 'e.g. 50000',
                prefixIcon: Align(
                  widthFactor: 1.0,
                  child: Text(
                    Get.find<HomeController>().currencySymbol.value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColor.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColor.border),
                ),
                child: Row(
                  children: [
                    PhosphorIcon(PhosphorIconsLight.calendar, color: AppColor.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _targetDate == null
                          ? 'Target date (optional)'
                          : DateFormat('d MMM yyyy').format(_targetDate!),
                      style: AppTypography.body(_targetDate == null ? AppColor.textTertiary : AppColor.textPrimary),
                    ),
                    const Spacer(),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
                        child: const PhosphorIcon(PhosphorIconsLight.x, size: 16, color: AppColor.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create goal'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD BILL SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddBillSheet extends StatefulWidget {
  final RecurringBillsController controller;

  const _AddBillSheet({required this.controller});

  @override
  State<_AddBillSheet> createState() => _AddBillSheetState();
}

// Popular services: (label, simpleicons-slug, bg-color, form-fill name)
const _kPopularServices = <(String, String, Color, String)>[
  ('YouTube',      'youtube',          Color(0xFFFF0000), 'YouTube Premium'),
  ('Spotify',      'spotify',          Color(0xFF1DB954), 'Spotify'),
  ('Netflix',      'netflix',          Color(0xFFE50914), 'Netflix'),
  ('Prime Video',  'primevideo',       Color(0xFF00A8E0), 'Amazon Prime'),
  ('iCloud',       'icloud',           Color(0xFF3693F3), 'Apple iCloud'),
  ('Hotstar',      'disneyplus',       Color(0xFF113CCF), 'Disney+ Hotstar'),
  ('ChatGPT',      'openai',           Color(0xFF412991), 'ChatGPT Plus'),
  ('LinkedIn',     'linkedin',         Color(0xFF0077B5), 'LinkedIn Premium'),
  ('Microsoft',    'microsoft',        Color(0xFF00BCF2), 'Microsoft 365'),
  ('Adobe',        'adobe',            Color(0xFFFF0000), 'Adobe Creative Cloud'),
  ('Notion',       'notion',           Color(0xFF000000), 'Notion'),
  ('GitHub',       'github',           Color(0xFF181717), 'GitHub Pro'),
  ('Figma',        'figma',            Color(0xFF0ACF83), 'Figma'),
  ('Canva',        'canva',            Color(0xFF00C4CC), 'Canva Pro'),
  ('Dropbox',      'dropbox',          Color(0xFF0061FF), 'Dropbox'),
  ('Jio',          'jio',              Color(0xFF0055A5), 'Jio'),
  ('Airtel',       'airtel',           Color(0xFFE40000), 'Airtel'),
  ('ZEE5',         'zee5',             Color(0xFF8B2FC9), 'ZEE5'),
];

class _AddBillSheetState extends State<_AddBillSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _frequency = 'monthly';
  int _dueDay = 1;
  bool _isSaving = false;
  String? _selectedService;

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a subscription name')));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _isSaving = true);
    await widget.controller.addBillManually(merchantName: name, amount: amount, frequency: _frequency, dueDay: _dueDay);
    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColor.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Add subscription', style: AppTypography.heading2(AppColor.textPrimary)),
            const SizedBox(height: 16),

            // Popular services grid
            Text('POPULAR SERVICES', style: GoogleFonts.urbanist(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColor.textTertiary, letterSpacing: 0.8,
            )),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.82,
              ),
              itemCount: _kPopularServices.length,
              itemBuilder: (_, i) {
                final svc = _kPopularServices[i];
                final label    = svc.$1;
                final slug     = svc.$2;
                final bg       = svc.$3;
                final fillName = svc.$4;
                final isSelected = _selectedService == slug;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedService = slug);
                    _nameController.text = fillName;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected ? bg.withValues(alpha: 0.12) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? bg : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.network(
                            'https://cdn.simpleicons.org/$slug/ffffff',
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) => Center(
                              child: Text(label[0],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(label[0],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: GoogleFonts.urbanist(
                            fontSize: 10, fontWeight: FontWeight.w500,
                            color: isSelected ? bg : AppColor.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColor.border, height: 1),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Netflix, Jio, Rent',
                prefixIcon: PhosphorIcon(PhosphorIconsLight.tag),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g. 649',
                prefixIcon: Align(
                  widthFactor: 1.0,
                  child: Text(
                    Get.find<HomeController>().currencySymbol.value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColor.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Billing cycle', style: AppTypography.bodySemiBold(AppColor.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ['monthly', 'quarterly', 'yearly'].map((f) {
                final selected = _frequency == f;
                return GestureDetector(
                  onTap: () => setState(() => _frequency = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColor.primary : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? AppColor.primary : AppColor.border),
                    ),
                    child: Text(
                      '${f[0].toUpperCase()}${f.substring(1)}',
                      style: AppTypography.bodySemiBold(selected ? Colors.white : AppColor.textSecondary),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Billing day', style: AppTypography.bodySemiBold(AppColor.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _daySuffix(_dueDay),
                    style: AppTypography.bodySemiBold(AppColor.primary),
                  ),
                ),
              ],
            ),
            Slider(
              value: _dueDay.toDouble(),
              min: 1, max: 31, divisions: 30,
              label: '${_dueDay}th',
              activeColor: AppColor.primary,
              onChanged: (v) => setState(() => _dueDay = v.round()),
            ),
            Text(
              'For months with fewer days, the last day will be used.',
              style: AppTypography.caption(AppColor.textTertiary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add subscription'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD MONEY SHEET
// ─────────────────────────────────────────────────────────────────────────────

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _isSaving = true);
    await widget.controller.addSavings(widget.goal.id, amount);
    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0', 'en_IN');
    final remaining = widget.goal.targetAmount - widget.goal.savedAmount;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColor.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(widget.goal.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.goal.name,
                          style: AppTypography.heading2(AppColor.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('$sym${fmt.format(remaining)} still needed',
                          style: AppTypography.caption(AppColor.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount to add ($sym)',
                prefixText: sym,
                hintText: 'e.g. 1000',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add to savings'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
