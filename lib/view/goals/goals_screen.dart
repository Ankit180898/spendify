import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/savings_controller/savings_controller.dart';
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
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
    if (!Get.isRegistered<SavingsController>()) {
      Get.put(SavingsController());
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
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final tabBorder = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    final spendingC = Get.find<GoalsController>();
    final savingsC = Get.find<SavingsController>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Goals', style: AppTypography.heading2(textPrimary)),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              if (_tabIndex == 0) {
                _showAddBudgetSheet(context, spendingC);
              } else {
                _showAddSavingsSheet(context, savingsC);
              }
            },
            icon: const PhosphorIcon(PhosphorIconsLight.plusCircle),
          ),
        ],
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BudgetTab(controller: spendingC, isDark: isDark),
          _SavingsTab(controller: savingsC, isDark: isDark),
        ],
      ),
    );
  }

  void _showAddBudgetSheet(BuildContext ctx, GoalsController controller) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBudgetSheet(controller: controller),
    );
  }

  void _showAddSavingsSheet(BuildContext ctx, SavingsController controller) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSavingsSheet(controller: controller),
    );
  }
}

// ── Budget Tab ────────────────────────────────────────────────────────────────

class _BudgetTab extends StatelessWidget {
  final GoalsController controller;
  final bool isDark;

  const _BudgetTab({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final dividerColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.goals.isEmpty) {
        return _EmptyView(
          icon: PhosphorIconsLight.wallet,
          title: 'No budget limits yet',
          subtitle:
              'Set monthly or weekly spending limits per category and get\nalerted when you go over.',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      }

      // Compute totals for summary
      double totalLimit = 0;
      double totalSpent = 0;
      for (final g in controller.goals) {
        totalLimit += g.limitAmount;
        totalSpent += controller.currentSpending(g);
      }
      final totalProgress =
          totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;

      return RefreshIndicator(
        onRefresh: controller.fetchGoals,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // Summary card (Five Cents-style header)
            Padding(
              padding: const EdgeInsets.all(AppDimens.spaceLG),
              child: _BudgetSummaryCard(
                totalLimit: totalLimit,
                totalSpent: totalSpent,
                totalProgress: totalProgress,
                isDark: isDark,
              ),
            ),
            // Category rows in a unified table
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
                style: AppTypography.caption(
                    isDark ? AppColor.textTertiary : AppColor.lightTextTertiary),
                textAlign: TextAlign.center,
              ),
            ),
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
              PhosphorIcon(PhosphorIconsLight.calendar, color: textMuted,
                  size: AppDimens.iconSM),
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
                  value: '${Get.find<HomeController>().currencySymbol.value}${fmt.format(totalLimit)}',
                  color: textPrimary,
                ),
              ),
              Expanded(
                child: _SummaryCol(
                  label: 'Spent',
                  value: '${Get.find<HomeController>().currencySymbol.value}${fmt.format(totalSpent)}',
                  color: textPrimary,
                ),
              ),
              Expanded(
                child: _SummaryCol(
                  label: isOver ? 'Over by' : 'Remaining',
                  value: '${Get.find<HomeController>().currencySymbol.value}${fmt.format(remaining.abs())}',
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
    final barColor =
        isOver ? AppColor.expense : isNear ? AppColor.warning : AppColor.income;
    final iconBg = isDark ? AppColor.darkElevated : const Color(0xFFF4F4F8);
    final iconFg = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.spaceXXL),
        color: AppColor.expense.withValues(alpha: 0.10),
        child: const PhosphorIcon(PhosphorIconsLight.trash, color: AppColor.expense),
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
                          goal.category == 'All' ? 'Total Spending' : goal.category,
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
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchGoals,
        child: ListView.separated(
          padding:
              const EdgeInsets.all(AppDimens.spaceLG).copyWith(bottom: 100),
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
      final days = goal.targetDate!.difference(DateTime.now()).inDays;
      daysLabel = days < 0
          ? 'Past due'
          : days == 0
              ? 'Due today'
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
        child: const PhosphorIcon(PhosphorIconsLight.trash, color: AppColor.expense),
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
                        style:
                            AppTypography.captionSemiBold(AppColor.income)),
                  ),
              ],
            ),
            const SizedBox(height: AppDimens.spaceXL),

            // Amount row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${Get.find<HomeController>().currencySymbol.value}${fmt.format(goal.savedAmount)} saved',
                    style: AppTypography.bodySemiBoldTabular(textPrimary)),
                Text('of ${Get.find<HomeController>().currencySymbol.value}${fmt.format(goal.targetAmount)}',
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
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusCircle),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 8,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusCircle),
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
  final Color textPrimary;
  final Color textSecondary;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
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
            Text('Tap + to get started',
                style: AppTypography.captionSemiBold(AppColor.primary)),
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
                  color:
                      isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusCircle),
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
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Limit amount (₹)',
                prefixIcon: PhosphorIcon(PhosphorIconsLight.currencyDollar),
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
                  padding:
                      const EdgeInsets.only(right: AppDimens.spaceSM),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.spaceLG,
                          vertical: AppDimens.spaceSM),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColor.primary : chipBg,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMD),
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
            Text('Category',
                style: AppTypography.bodySemiBold(textPrimary)),
            const SizedBox(height: AppDimens.spaceSM),
            Wrap(
              spacing: AppDimens.spaceSM,
              runSpacing: AppDimens.spaceSM,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.spaceMD,
                        vertical: AppDimens.spaceSM),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColor.primary.withValues(alpha: 0.12)
                          : chipBg,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusMD),
                      border: Border.all(
                        color: isSelected
                            ? AppColor.primary
                            : (isDark
                                ? AppColor.darkBorder
                                : AppColor.lightBorder),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: AppTypography.body(
                        isSelected ? AppColor.primary : textSecondary,
                      ),
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
    '🎯', '🏖️', '✈️', '🚗', '🏠', '💍',
    '📱', '🎓', '🏋️', '💊', '🛍️', '🍕',
    '🎮', '🎸', '🐶', '🌱', '📷', '🎁',
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
                  color:
                      isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusCircle),
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
                            : (isDark
                                ? AppColor.darkCard
                                : AppColor.lightBg),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMD),
                        border: Border.all(
                          color: isSelected
                              ? AppColor.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(e,
                            style: const TextStyle(fontSize: 20)),
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
                decoration: const InputDecoration(
                  labelText: 'Target amount (₹)',
                  hintText: 'e.g. 50000',
                  prefixIcon: PhosphorIcon(PhosphorIconsLight.currencyDollar),
                ),
              ),
              const SizedBox(height: AppDimens.spaceMD),

              // Target date (optional)
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spaceLG,
                      vertical: AppDimens.spaceMD),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColor.darkSurface
                        : AppColor.lightSurface,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusMD),
                    border: Border.all(
                      color: isDark
                          ? AppColor.darkBorder
                          : AppColor.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(PhosphorIconsLight.calendar,
                          color: textSecondary,
                          size: AppDimens.iconMD),
                      const SizedBox(width: AppDimens.spaceMD),
                      Text(
                        _targetDate == null
                            ? 'Target date (optional)'
                            : DateFormat('d MMM yyyy')
                                .format(_targetDate!),
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
                          onTap: () =>
                              setState(() => _targetDate = null),
                          child: PhosphorIcon(PhosphorIconsLight.x,
                              size: AppDimens.iconSM,
                              color: textSecondary),
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
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
                  color:
                      isDark ? AppColor.darkBorder : AppColor.lightBorder,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusCircle),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spaceXXL),
            Row(
              children: [
                Text(widget.goal.emoji,
                    style: const TextStyle(fontSize: 24)),
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
              decoration: const InputDecoration(
                labelText: 'Amount to add (₹)',
                prefixIcon: PhosphorIcon(PhosphorIconsLight.currencyDollar),
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
