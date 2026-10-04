import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

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
import 'package:spendify/widgets/celebration.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

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
      backgroundColor: AppColor.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 10, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goals',
                          style: GoogleFonts.urbanist(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        Text(
                          'Plan it, save it, stay on track',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      showGoalsAddPicker(context);
                    },
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColor.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: PhosphorIcon(PhosphorIconsBold.plus,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Overview banner — ties the three tabs together ──────
            _GoalsOverview(
              spendingC: spendingC,
              savingsC: savingsC,
              billsC: billsC,
              onSelect: (i) {
                HapticFeedback.selectionClick();
                _tabController.animateTo(i);
              },
            ),
            const SizedBox(height: 16),

            // ── Segmented switcher ──────────────────────────────────
            _SegmentedTabs(
              controller: _tabController,
              labels: const ['Budgets', 'Savings', 'Bills'],
            ),
            const SizedBox(height: 4),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BudgetTab(controller: spendingC),
                  _SavingsTab(controller: savingsC),
                  _BillsTab(controller: billsC),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview banner
// ─────────────────────────────────────────────────────────────────────────────

double _monthExpense(HomeController hc) {
  final now = DateTime.now();
  return hc.allTransactions.where((t) {
    if (t['type'] != 'expense') return false;
    final d = DateTime.tryParse(t['date'] ?? '');
    return d != null && d.year == now.year && d.month == now.month;
  }).fold(0.0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0.0));
}

String _compact(double v, String sym) {
  final a = v.abs();
  final sign = v < 0 ? '−' : '';
  if (a >= 100000) return '$sign$sym${(a / 100000).toStringAsFixed(1)}L';
  if (a >= 1000) return '$sign$sym${(a / 1000).toStringAsFixed(1)}K';
  return '$sign$sym${NumberFormat('#,##0', 'en_IN').format(a)}';
}

class _GoalsOverview extends StatelessWidget {
  final GoalsController spendingC;
  final SavingsController savingsC;
  final RecurringBillsController billsC;
  final ValueChanged<int> onSelect;

  const _GoalsOverview({
    required this.spendingC,
    required this.savingsC,
    required this.billsC,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hc = Get.find<HomeController>();
    return Obx(() {
      final sym = hc.currencySymbol.value;
      final budget = hc.monthlyBudget.value;
      final spent = _monthExpense(hc);
      final saved = savingsC.goals.fold(0.0, (s, g) => s + g.savedAmount);
      final target = savingsC.goals.fold(0.0, (s, g) => s + g.targetAmount);
      final monthlyBills = billsC.bills.fold(0.0, (s, b) {
        switch (b.frequency) {
          case 'yearly':
            return s + b.amount / 12;
          case 'quarterly':
            return s + b.amount / 3;
          default:
            return s + b.amount;
        }
      });

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColor.bannerBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  icon: PhosphorIconsDuotone.shieldCheck,
                  color: AppColor.catCar,
                  value: budget > 0 ? _compact(budget - spent, sym) : '—',
                  label: budget > 0
                      ? (budget - spent >= 0 ? 'Budget left' : 'Over budget')
                      : 'No budget',
                  onTap: () => onSelect(0),
                ),
              ),
              Container(width: 1, height: 44, color: AppColor.borderStrong.withValues(alpha: 0.6)),
              Expanded(
                child: _OverviewStat(
                  icon: PhosphorIconsDuotone.piggyBank,
                  color: AppColor.income,
                  value: _compact(saved, sym),
                  label: target > 0
                      ? '${(saved / target * 100).clamp(0, 100).round()}% saved'
                      : 'Saved',
                  onTap: () => onSelect(1),
                ),
              ),
              Container(width: 1, height: 44, color: AppColor.borderStrong.withValues(alpha: 0.6)),
              Expanded(
                child: _OverviewStat(
                  icon: PhosphorIconsDuotone.calendarCheck,
                  color: AppColor.warning,
                  value: _compact(monthlyBills, sym),
                  label: 'Bills / month',
                  onTap: () => onSelect(2),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _OverviewStat extends StatelessWidget {
  final Object icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _OverviewStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColor.surface.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(icon, size: 18, color: color,
                    duotoneSecondaryOpacity: 0.3),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.urbanist(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill segmented control driven by the TabController
// ─────────────────────────────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  const _SegmentedTabs({required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColor.surfaceVariant,
            borderRadius: BorderRadius.circular(100),
          ),
          child: LayoutBuilder(
            builder: (_, c) {
              final w = c.maxWidth / labels.length;
              return AnimatedBuilder(
                animation: controller.animation!,
                builder: (_, __) {
                  final pos = controller.animation!.value;
                  return Stack(
                    children: [
                      Positioned(
                        left: pos * w,
                        width: w,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColor.surface,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: AppColor.primary.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(labels.length, (i) {
                          final active = (pos - i).abs() < 0.5;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                controller.animateTo(i);
                              },
                              child: Center(
                                child: Text(
                                  labels[i],
                                  style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                    color: active ? AppColor.textPrimary : AppColor.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point called from Home and the Goals header.
// ─────────────────────────────────────────────────────────────────────────────

void showGoalsAddPicker(BuildContext ctx) {
  final spendingC = Get.find<GoalsController>();
  if (!Get.isRegistered<SavingsController>()) Get.put(SavingsController());
  if (!Get.isRegistered<RecurringBillsController>()) Get.put(RecurringBillsController());
  final savingsC = Get.find<SavingsController>();
  final billsC = Get.find<RecurringBillsController>();

  void open(Widget sheet) => showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => sheet,
      );

  showModalBottomSheet(
    context: ctx,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Create a goal',
            style: GoogleFonts.urbanist(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColor.heading,
            ),
          ),
          const SizedBox(height: 14),
          _PickerOption(
            icon: PhosphorIconsDuotone.shieldCheck,
            color: AppColor.catCar,
            label: 'Budget limit',
            subtitle: 'Cap spending for a category',
            onTap: () {
              Navigator.pop(sheetCtx);
              open(_AddBudgetSheet(controller: spendingC));
            },
          ),
          const SizedBox(height: 10),
          _PickerOption(
            icon: PhosphorIconsDuotone.piggyBank,
            color: AppColor.income,
            label: 'Savings goal',
            subtitle: 'Save toward something you want',
            onTap: () {
              Navigator.pop(sheetCtx);
              open(_AddSavingsSheet(controller: savingsC));
            },
          ),
          const SizedBox(height: 10),
          _PickerOption(
            icon: PhosphorIconsDuotone.calendarCheck,
            color: AppColor.warning,
            label: 'Subscription',
            subtitle: 'Track a recurring payment',
            onTap: () {
              Navigator.pop(sheetCtx);
              open(_AddBillSheet(controller: billsC));
            },
          ),
        ],
      ),
    ),
  );
}

class _PickerOption extends StatelessWidget {
  final Object icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.color,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.borderStrong),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(icon, color: color, size: 22,
                    duotoneSecondaryOpacity: 0.3),
              ),
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
            const PhosphorIcon(PhosphorIconsLight.caretRight,
                color: AppColor.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared goal pieces
// ─────────────────────────────────────────────────────────────────────────────

Color _statusColor(double pct) => pct >= 1
    ? AppColor.expense
    : pct >= 0.8
        ? AppColor.warning
        : AppColor.income;

class _ListTitle extends StatelessWidget {
  final String text;
  final String? trailing;
  const _ListTitle(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
        child: Row(
          children: [
            Text(
              text,
              style: GoogleFonts.urbanist(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColor.heading,
              ),
            ),
            const Spacer(),
            if (trailing != null)
              Text(trailing!, style: AppTypography.caption(AppColor.textTertiary)),
          ],
        ),
      );
}

class _AnimatedBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const _AnimatedBar({required this.value, required this.color, this.height = 6});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: v,
            minHeight: height,
            backgroundColor: AppColor.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label, style: AppTypography.captionSemiBold(color)),
      );
}

class _DeleteBackground extends StatelessWidget {
  final double radius;
  const _DeleteBackground({this.radius = 16});

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColor.expense.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: const PhosphorIcon(PhosphorIconsDuotone.trash,
            color: AppColor.expense, duotoneSecondaryOpacity: 0.3),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// BUDGET TAB
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetTab extends StatelessWidget {
  final GoalsController controller;

  const _BudgetTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hc = Get.find<HomeController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColor.primary));
      }

      final monthlyBudget = hc.monthlyBudget.value;
      final hasMonthlyBudget = monthlyBudget > 0;
      final goals = controller.goals.toList();

      if (!hasMonthlyBudget && goals.isEmpty) {
        return _EmptyView(
          icon: PhosphorIconsDuotone.shieldCheck,
          color: AppColor.catCar,
          title: 'No budgets yet',
          subtitle: 'Cap what you spend on food, shopping or anything else — we\'ll nudge you before you go over.',
          cta: 'Add a budget',
          onAction: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddBudgetSheet(controller: controller),
          ),
        );
      }

      final onTrack = goals
          .where((g) => g.limitAmount > 0 && controller.currentSpending(g) < g.limitAmount)
          .length;

      return RefreshIndicator(
        color: AppColor.primary,
        onRefresh: controller.fetchGoals,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            if (hasMonthlyBudget)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _MonthlyBudgetCard(budget: monthlyBudget, spent: _monthExpense(hc)),
              ),
            if (goals.isNotEmpty) ...[
              _ListTitle('Category limits', trailing: '$onTrack of ${goals.length} on track'),
              for (var i = 0; i < goals.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _BudgetRow(goal: goals[i], controller: controller, index: i),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Swipe left to remove a limit',
                  style: AppTypography.caption(AppColor.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _InlineCta(
                  icon: PhosphorIconsDuotone.plusCircle,
                  text: 'Add category limits to see where your budget goes',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _AddBudgetSheet(controller: controller),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _InlineCta extends StatelessWidget {
  final Object icon;
  final String text;
  final VoidCallback onTap;
  const _InlineCta({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.primaryExtraSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.border),
          ),
          child: Row(
            children: [
              PhosphorIcon(icon, color: AppColor.primary, size: 22,
                  duotoneSecondaryOpacity: 0.3),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text, style: AppTypography.bodySemiBold(AppColor.textPrimary)),
              ),
            ],
          ),
        ),
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
    final pct = spent / budget;
    final color = _statusColor(pct);
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final perDay = isOver ? 0.0 : remaining / daysLeft;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.borderStrong),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColor.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(pct * 100).round()}%',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Text('used', style: AppTypography.caption(AppColor.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('MMMM').format(now)} budget',
                  style: AppTypography.caption(AppColor.textTertiary),
                ),
                const SizedBox(height: 2),
                Text(
                  isOver
                      ? '$sym${fmt.format(-remaining)} over'
                      : '$sym${fmt.format(remaining)} left',
                  style: GoogleFonts.urbanist(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isOver ? AppColor.expense : AppColor.textPrimary,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '$sym${fmt.format(spent)} of $sym${fmt.format(budget)} spent',
                  style: AppTypography.caption(AppColor.textSecondary),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    isOver
                        ? 'Try to pause non-essentials'
                        : '$sym${fmt.format(perDay)}/day for $daysLeft ${daysLeft == 1 ? 'day' : 'days'}',
                    style: AppTypography.captionSemiBold(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final SpendingGoal goal;
  final GoalsController controller;
  final int index;

  const _BudgetRow({required this.goal, required this.controller, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final sym = Get.find<HomeController>().currencySymbol.value;
    final spent = controller.currentSpending(goal);
    final pct = goal.limitAmount > 0 ? spent / goal.limitAmount : 0.0;
    final isOver = spent > goal.limitAmount;
    final isNear = !isOver && pct >= 0.8;
    final barColor = _statusColor(pct);
    final catColor = goal.category == 'All'
        ? AppColor.primary
        : AppColor.categoryColor(goal.category);
    final left = goal.limitAmount - spent;

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      onDismissed: (_) => controller.deleteGoal(goal.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.borderStrong),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: PhosphorIcon(_categoryIcon(goal.category),
                        color: catColor, size: 21, duotoneSecondaryOpacity: 0.3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.category == 'All' ? 'Total spending' : goal.category,
                        style: AppTypography.bodySemiBold(AppColor.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$sym${fmt.format(spent)} of $sym${fmt.format(goal.limitAmount)} · ${goal.period}',
                        style: AppTypography.caption(AppColor.textSecondary),
                      ),
                    ],
                  ),
                ),
                _StatusChip(
                  isOver
                      ? 'Over'
                      : isNear
                          ? 'Near limit'
                          : 'On track',
                  barColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AnimatedBar(value: pct, color: barColor),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${(pct * 100).round()}% used',
                    style: AppTypography.caption(AppColor.textTertiary)),
                const Spacer(),
                Text(
                  isOver
                      ? '$sym${fmt.format(-left)} over'
                      : '$sym${fmt.format(left)} left',
                  style: AppTypography.captionSemiBold(
                      isOver ? AppColor.expense : AppColor.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Object _categoryIcon(String category) {
    if (category == 'All') return PhosphorIconsDuotone.wallet;
    final k = category.toLowerCase();
    if (k.contains('invest')) return PhosphorIconsDuotone.trendUp;
    if (k.contains('health') || k.contains('medical')) return PhosphorIconsDuotone.heartbeat;
    if (k.contains('bill') || k.contains('fee')) return PhosphorIconsDuotone.receipt;
    if (k.contains('food') || k.contains('drink')) return PhosphorIconsDuotone.forkKnife;
    if (k.contains('car') || k.contains('vehicle')) return PhosphorIconsDuotone.car;
    if (k.contains('grocer')) return PhosphorIconsDuotone.shoppingCart;
    if (k.contains('shop')) return PhosphorIconsDuotone.shoppingBag;
    if (k.contains('gift')) return PhosphorIconsDuotone.gift;
    if (k.contains('transport')) return PhosphorIconsDuotone.bus;
    if (k.contains('travel')) return PhosphorIconsDuotone.airplaneTilt;
    if (k.contains('entertain')) return PhosphorIconsDuotone.filmSlate;
    if (k.contains('educat')) return PhosphorIconsDuotone.graduationCap;
    return PhosphorIconsDuotone.squaresFour;
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

      void addGoal() => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddSavingsSheet(controller: controller),
          );

      if (controller.goals.isEmpty) {
        return _EmptyView(
          icon: PhosphorIconsDuotone.piggyBank,
          color: AppColor.income,
          title: 'Start your first savings goal',
          subtitle: 'A trip, a gadget, an emergency fund — set a target and watch it fill up. We celebrate every milestone.',
          cta: 'Create a goal',
          onAction: addGoal,
        );
      }

      final goals = controller.goals.toList()
        ..sort((a, b) {
          // Active goals first, closest to done on top
          final da = a.savedAmount >= a.targetAmount;
          final db = b.savedAmount >= b.targetAmount;
          if (da != db) return da ? 1 : -1;
          final pa = a.targetAmount > 0 ? a.savedAmount / a.targetAmount : 0;
          final pb = b.targetAmount > 0 ? b.savedAmount / b.targetAmount : 0;
          return pb.compareTo(pa);
        });
      final done = goals.where((g) => g.savedAmount >= g.targetAmount).length;

      return RefreshIndicator(
        color: AppColor.primary,
        onRefresh: controller.fetchGoals,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            _ListTitle('Your goals',
                trailing: done > 0 ? '$done of ${goals.length} reached' : '${goals.length} active'),
            for (final g in goals)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _SavingsGoalCard(
                  goal: g,
                  controller: controller,
                  onAddMoney: () => _showAddMoneySheet(context, controller, g),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _InlineCta(
                icon: PhosphorIconsDuotone.plusCircle,
                text: 'Add another goal',
                onTap: addGoal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Swipe left to remove a goal',
              style: AppTypography.caption(AppColor.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final pct = goal.targetAmount > 0 ? goal.savedAmount / goal.targetAmount : 0.0;
    final isComplete = goal.savedAmount >= goal.targetAmount;
    final color = isComplete ? AppColor.income : AppColor.primary;
    final remaining = (goal.targetAmount - goal.savedAmount).clamp(0.0, double.infinity);

    String? daysLabel;
    Color daysColor = AppColor.textSecondary;
    if (goal.targetDate != null && !isComplete) {
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
      if (days <= 7) daysColor = days < 0 ? AppColor.expense : AppColor.warning;
      // Suggest a weekly pace when there's time left
      if (days > 7 && remaining > 0) {
        final perWeek = remaining / (days / 7);
        daysLabel = '$daysLabel · ~$sym${fmt.format(perWeek)}/week';
      }
    }

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(radius: 18),
      onDismissed: (_) => controller.deleteGoal(goal.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isComplete ? AppColor.income.withValues(alpha: 0.05) : AppColor.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isComplete ? AppColor.income.withValues(alpha: 0.35) : AppColor.borderStrong,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Emoji inside an animated progress ring
                SizedBox(
                  width: 60,
                  height: 60,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: v,
                            strokeWidth: 4.5,
                            strokeCap: StrokeCap.round,
                            backgroundColor: AppColor.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                        Text(goal.emoji, style: const TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: '$sym${fmt.format(goal.savedAmount)}',
                            style: AppTypography.bodySemiBoldTabular(AppColor.textPrimary),
                          ),
                          TextSpan(
                            text: ' of $sym${fmt.format(goal.targetAmount)}',
                            style: AppTypography.caption(AppColor.textSecondary),
                          ),
                        ]),
                      ),
                      if (daysLabel != null)
                        Text(daysLabel, style: AppTypography.caption(daysColor)),
                    ],
                  ),
                ),
                if (isComplete)
                  const _StatusChip('Reached', AppColor.income)
                else
                  Text(
                    '${(pct * 100).round()}%',
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _MilestoneTrack(progress: pct, color: color),
            if (!isComplete) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onAddMoney();
                  },
                  icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 14, color: Colors.white),
                  label: Text(
                    'Add money · $sym${fmt.format(remaining)} to go',
                    style: AppTypography.bodySemiBold(Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Progress bar with 25 / 50 / 75 / 100% milestone pips.
class _MilestoneTrack extends StatelessWidget {
  final double progress;
  final Color color;
  const _MilestoneTrack({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) {
          const pip = 16.0;
          final w = c.maxWidth - pip;
          return SizedBox(
            height: pip,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: pip / 2),
                  child: _AnimatedBar(value: progress, color: color, height: 6),
                ),
                for (final m in const [0.25, 0.5, 0.75, 1.0])
                  Positioned(
                    left: w * m,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: pip,
                      height: pip,
                      decoration: BoxDecoration(
                        color: progress >= m ? color : AppColor.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: progress >= m ? AppColor.surface : AppColor.borderStrong,
                          width: 2,
                        ),
                      ),
                      child: progress >= m
                          ? const Center(
                              child: PhosphorIcon(PhosphorIconsBold.check,
                                  size: 8, color: Colors.white),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          );
        },
      );
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

/// Where a bill stands for one calendar month.
class _BillMonthStatus {
  final String label;
  final Color color;
  final bool paid;
  final bool canToggle;
  const _BillMonthStatus(this.label, this.color, {this.paid = false, this.canToggle = false});
}

_BillMonthStatus _statusFor(RecurringBill bill, DateTime month) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = bill.dueDateIn(month.year, month.month);
  final thisMonth = DateTime(now.year, now.month);
  final fmt = DateFormat('d MMM');

  if (month.isBefore(thisMonth)) {
    return _BillMonthStatus('Was due ${fmt.format(due)}', AppColor.textTertiary);
  }
  if (month.isAfter(thisMonth)) {
    return _BillMonthStatus('Due ${fmt.format(due)}', AppColor.textSecondary);
  }
  if (bill.isPaidFor(due)) {
    return const _BillMonthStatus('Paid', AppColor.income, paid: true, canToggle: true);
  }
  final days = due.difference(today).inDays;
  if (days < 0) {
    return _BillMonthStatus(
        days == -1 ? 'Overdue · 1 day' : 'Overdue · ${-days} days', AppColor.expense,
        canToggle: true);
  }
  if (days == 0) return const _BillMonthStatus('Due today', AppColor.warning, canToggle: true);
  if (days == 1) return const _BillMonthStatus('Due tomorrow', AppColor.warning, canToggle: true);
  return _BillMonthStatus('Due in $days days', AppColor.textSecondary, canToggle: true);
}

class _BillsTabState extends State<_BillsTab> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta));
  }

  List<RecurringBill> _billsInView() => widget.controller.bills
      .where((b) => b.isActive && b.isDueInMonth(_viewMonth.year, _viewMonth.month))
      .toList()
    ..sort((a, b) => a
        .dueDateIn(_viewMonth.year, _viewMonth.month)
        .compareTo(b.dueDateIn(_viewMonth.year, _viewMonth.month)));

  void _showDaySheet(BuildContext ctx, DateTime date, List<RecurringBill> bills) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DayBillsSheet(
        date: date,
        month: _viewMonth,
        billIds: bills.map((b) => b.id).toList(),
        controller: widget.controller,
      ),
    );
  }

  void _addBill(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddBillSheet(controller: widget.controller),
      );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.isLoading.value && widget.controller.bills.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppColor.primary));
      }

      final suggestions = widget.controller.suggestions.toList();
      final hasBills = widget.controller.bills.isNotEmpty;

      if (suggestions.isEmpty && !hasBills) {
        return _EmptyView(
          icon: PhosphorIconsDuotone.calendarCheck,
          color: AppColor.warning,
          title: 'No subscriptions yet',
          subtitle: 'Spendify spots recurring payments as you log transactions, or add one yourself.',
          cta: 'Add a subscription',
          onAction: () => _addBill(context),
        );
      }

      final inView = _billsInView();
      final statuses = {for (final b in inView) b.id: _statusFor(b, _viewMonth)};
      // Unpaid first (by due date), paid last
      final ordered = [
        ...inView.where((b) => !statuses[b.id]!.paid),
        ...inView.where((b) => statuses[b.id]!.paid),
      ];

      return RefreshIndicator(
        color: AppColor.primary,
        onRefresh: widget.controller.fetchBills,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _BillsSummaryCard(
                month: _viewMonth,
                bills: inView,
                statuses: statuses,
                onPrev: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
                onToday: () {
                  final now = DateTime.now();
                  setState(() => _viewMonth = DateTime(now.year, now.month));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _CalendarCard(
                month: _viewMonth,
                bills: inView,
                statuses: statuses,
                onDayTap: (date, bills) => _showDaySheet(context, date, bills),
              ),
            ),

            if (suggestions.isNotEmpty) ...[
              const _ListTitle('Detected for you'),
              for (final s in suggestions)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _SuggestionCard(suggestion: s, controller: widget.controller),
                ),
            ],

            _ListTitle(
              DateFormat('MMMM').format(_viewMonth),
              trailing: inView.isEmpty
                  ? null
                  : '${inView.length} ${inView.length == 1 ? 'bill' : 'bills'}',
            ),
            if (inView.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Nothing due this month.',
                  style: AppTypography.body(AppColor.textSecondary),
                ),
              )
            else
              for (final b in ordered)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _BillListRow(
                    bill: b,
                    month: _viewMonth,
                    status: statuses[b.id]!,
                    controller: widget.controller,
                  ),
                ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: _InlineCta(
                icon: PhosphorIconsDuotone.plusCircle,
                text: 'Add a subscription',
                onTap: () => _addBill(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Swipe left on a bill to remove it',
              style: AppTypography.caption(AppColor.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    });
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _BillsSummaryCard extends StatelessWidget {
  final DateTime month;
  final List<RecurringBill> bills;
  final Map<String, _BillMonthStatus> statuses;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _BillsSummaryCard({
    required this.month,
    required this.bills,
    required this.statuses,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0', 'en_IN');
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    final total = bills.fold(0.0, (s, b) => s + b.amount);
    final paid = bills
        .where((b) => statuses[b.id]!.paid)
        .fold(0.0, (s, b) => s + b.amount);
    final overdue = bills.where((b) => statuses[b.id]!.label.startsWith('Overdue')).length;
    final next = isCurrent
        ? bills.where((b) => !statuses[b.id]!.paid).toList()
        : <RecurringBill>[];

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.borderStrong),
      ),
      child: Column(
        children: [
          // Month switcher
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                visualDensity: VisualDensity.compact,
                icon: const PhosphorIcon(PhosphorIconsBold.caretLeft,
                    size: 16, color: AppColor.textSecondary),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: isCurrent ? null : onToday,
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(month),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      if (!isCurrent)
                        Text('Tap to jump to today',
                            style: AppTypography.caption(AppColor.primary)),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                visualDensity: VisualDensity.compact,
                icon: const PhosphorIcon(PhosphorIconsBold.caretRight,
                    size: 16, color: AppColor.textSecondary),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCurrent ? 'Due this month' : 'Total due',
                            style: AppTypography.caption(AppColor.textTertiary),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: total),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => Text(
                              '$sym${fmt.format(v)}',
                              style: GoogleFonts.urbanist(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColor.textPrimary,
                                letterSpacing: -0.8,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent && total > 0)
                      _StatusChip(
                        overdue > 0
                            ? '$overdue overdue'
                            : paid >= total
                                ? 'All paid'
                                : '${bills.where((b) => statuses[b.id]!.paid).length}/${bills.length} paid',
                        overdue > 0
                            ? AppColor.expense
                            : paid >= total
                                ? AppColor.income
                                : AppColor.primary,
                      ),
                  ],
                ),
                if (isCurrent && total > 0) ...[
                  const SizedBox(height: 12),
                  _AnimatedBar(value: paid / total, color: AppColor.income),
                  const SizedBox(height: 6),
                  Text(
                    '$sym${fmt.format(paid)} paid · $sym${fmt.format(total - paid)} to go',
                    style: AppTypography.caption(AppColor.textSecondary),
                  ),
                ],
                if (next.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColor.primaryExtraSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _ServiceDot(bill: next.first, size: 32, radius: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Next up', style: AppTypography.caption(AppColor.textTertiary)),
                              Text(
                                '${next.first.merchantName} · ${statuses[next.first.id]!.label.toLowerCase()}',
                                style: AppTypography.bodySemiBold(AppColor.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$sym${fmt.format(next.first.amount)}',
                          style: AppTypography.bodySemiBoldTabular(AppColor.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calendar ──────────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  final DateTime month;
  final List<RecurringBill> bills;
  final Map<String, _BillMonthStatus> statuses;
  final void Function(DateTime date, List<RecurringBill> bills) onDayTap;

  const _CalendarCard({
    required this.month,
    required this.bills,
    required this.statuses,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = DateTime(month.year, month.month, 1).weekday - 1; // Mon=0
    final rows = ((offset + daysInMonth) / 7).ceil();

    // Group by the *clamped* due day so 31st bills show in short months
    final byDay = <int, List<RecurringBill>>{};
    for (final b in bills) {
      byDay.putIfAbsent(b.dueDateIn(month.year, month.month).day, () => []).add(b);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.borderStrong),
      ),
      child: Column(
        children: [
          Row(
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textTertiary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < rows; r++)
            Row(
              children: List.generate(7, (c) {
                final day = r * 7 + c - offset + 1;
                if (day < 1 || day > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 52));
                }
                final date = DateTime(month.year, month.month, day);
                final dayBills = byDay[day] ?? const <RecurringBill>[];
                return Expanded(
                  child: _DayCell(
                    day: day,
                    bills: dayBills,
                    isToday: date == today,
                    isPast: date.isBefore(today),
                    allPaid: dayBills.isNotEmpty &&
                        dayBills.every((b) => statuses[b.id]?.paid ?? false),
                    anyOverdue: dayBills.any(
                        (b) => statuses[b.id]?.label.startsWith('Overdue') ?? false),
                    onTap: dayBills.isEmpty ? null : () => onDayTap(date, dayBills),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final List<RecurringBill> bills;
  final bool isToday;
  final bool isPast;
  final bool allPaid;
  final bool anyOverdue;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.bills,
    required this.isToday,
    required this.isPast,
    required this.allPaid,
    required this.anyOverdue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final has = bills.isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: has
              ? (anyOverdue
                  ? AppColor.expense.withValues(alpha: 0.07)
                  : AppColor.primaryExtraSoft)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: isToday
                  ? const BoxDecoration(color: AppColor.primary, shape: BoxShape.circle)
                  : null,
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: isToday || has ? FontWeight.w700 : FontWeight.w500,
                  color: isToday
                      ? Colors.white
                      : isPast && !has
                          ? AppColor.textTertiary.withValues(alpha: 0.6)
                          : AppColor.textPrimary,
                ),
              ),
            ),
            if (has) ...[
              const SizedBox(height: 3),
              SizedBox(
                height: 18,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ServiceDot(bill: bills.first, size: 16, radius: 8),
                        if (bills.length > 1) ...[
                          const SizedBox(width: 2),
                          Text('+${bills.length - 1}',
                              style: GoogleFonts.urbanist(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.textSecondary)),
                        ],
                      ],
                    ),
                    if (allPaid)
                      const Positioned(
                        right: -6,
                        top: -4,
                        child: _MiniBadge(color: AppColor.income, icon: PhosphorIconsBold.check),
                      )
                    else if (anyOverdue)
                      const Positioned(
                        right: -6,
                        top: -4,
                        child: _MiniBadge(color: AppColor.expense, icon: PhosphorIconsBold.exclamationMark),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final Color color;
  final PhosphorIconData icon;
  const _MiniBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColor.surface, width: 1.5),
        ),
        child: Center(child: PhosphorIcon(icon, size: 6, color: Colors.white)),
      );
}

/// Ticks a bill off for the month and plays the celebration.
Future<void> _togglePaid(
  RecurringBillsController controller,
  RecurringBill bill,
  DateTime month,
  bool paid,
) async {
  HapticFeedback.mediumImpact();
  final due = bill.dueDateIn(month.year, month.month);
  final ok = await controller.setPaid(bill, due, paid: paid);
  if (!ok) {
    CustomToast.errorToast('Couldn\'t update', 'Check your connection and try again.');
    return;
  }
  if (!paid) return;

  final sym = Get.find<HomeController>().currencySymbol.value;
  final fmt = NumberFormat('#,##0', 'en_IN');
  final left = controller.bills
      .where((b) => b.isActive && b.isDueInMonth(month.year, month.month))
      .where((b) => !b.isPaidFor(b.dueDateIn(month.year, month.month)))
      .toList();
  final leftAmt = left.fold(0.0, (s, b) => s + b.amount);

  showCelebration(CelebrationData(
    title: left.isEmpty ? 'All bills paid!' : 'Bill paid',
    subtitle: '${bill.merchantName} · $sym${fmt.format(bill.amount)}',
    icon: left.isEmpty ? PhosphorIconsDuotone.sealCheck : PhosphorIconsDuotone.checkCircle,
    color: AppColor.income,
    footnote: left.isEmpty
        ? 'Every bill for ${DateFormat('MMMM').format(month)} is settled.'
        : '${left.length} left this month · $sym${fmt.format(leftAmt)}',
  ));
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
    Color(0xFF86695B), Color(0xFF4F9A74), Color(0xFFD99A4E),
    Color(0xFFCB5F55), Color(0xFF6E8CA8), Color(0xFF9A7BB5),
    Color(0xFF5E8F8A),
  ];
  return palette[name.toLowerCase().codeUnits.fold(0, (s, c) => s + c) % palette.length];
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
  final DateTime month;
  final List<String> billIds;
  final RecurringBillsController controller;

  const _DayBillsSheet({
    required this.date,
    required this.month,
    required this.billIds,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Obx(() {
        // Re-read from the controller so ticking a bill updates in place
        final bills = controller.bills.where((b) => billIds.contains(b.id)).toList();
        final sym = Get.find<HomeController>().currencySymbol.value;
        final fmt = NumberFormat('#,##0.##', 'en_IN');
        final total = bills.fold(0.0, (s, b) => s + b.amount);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(DateFormat('EEEE, d MMMM').format(date),
                style: AppTypography.caption(AppColor.textTertiary)),
            Row(
              children: [
                Text(
                  bills.length == 1 ? '1 bill due' : '${bills.length} bills due',
                  style: GoogleFonts.urbanist(
                      fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                ),
                const Spacer(),
                Text('$sym${fmt.format(total)}',
                    style: GoogleFonts.urbanist(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
              ],
            ),
            const SizedBox(height: 14),
            for (final b in bills)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BillListRow(
                  bill: b,
                  month: month,
                  status: _statusFor(b, month),
                  controller: controller,
                  dismissible: false,
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ── Bill row ──────────────────────────────────────────────────────────────────

class _BillListRow extends StatelessWidget {
  final RecurringBill bill;
  final DateTime month;
  final _BillMonthStatus status;
  final RecurringBillsController controller;
  final bool dismissible;

  const _BillListRow({
    required this.bill,
    required this.month,
    required this.status,
    required this.controller,
    this.dismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0.##', 'en_IN');
    final freq = '${bill.frequency[0].toUpperCase()}${bill.frequency.substring(1)}';
    final due = bill.dueDateIn(month.year, month.month);

    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: status.paid ? AppColor.income.withValues(alpha: 0.05) : AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status.paid
              ? AppColor.income.withValues(alpha: 0.3)
              : status.label.startsWith('Overdue')
                  ? AppColor.expense.withValues(alpha: 0.35)
                  : AppColor.borderStrong,
        ),
      ),
      child: Row(
        children: [
          _ServiceDot(bill: bill, size: 40, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.merchantName,
                  style: AppTypography.bodySemiBold(AppColor.textPrimary).copyWith(
                    decoration: status.paid ? TextDecoration.lineThrough : null,
                    decorationColor: AppColor.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$freq · ${DateFormat('d MMM').format(due)}',
                  style: AppTypography.caption(AppColor.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$sym${fmt.format(bill.amount)}',
                  style: AppTypography.bodySemiBoldTabular(AppColor.textPrimary)),
              Text(status.label, style: AppTypography.captionSemiBold(status.color)),
            ],
          ),
          if (status.canToggle) ...[
            const SizedBox(width: 4),
            _PaidToggle(
              paid: status.paid,
              onTap: () => _togglePaid(controller, bill, month, !status.paid),
            ),
          ] else
            const SizedBox(width: 6),
        ],
      ),
    );

    if (!dismissible) return row;

    return Dismissible(
      key: Key('bill_${bill.id}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Remove ${bill.merchantName}?'),
            content: const Text('It will stop showing on your calendar and reminders.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove', style: TextStyle(color: AppColor.expense)),
              ),
            ],
          ),
        );
        if (ok != true) return false;
        final deleted = await controller.deleteBill(bill.id);
        if (!deleted) {
          CustomToast.errorToast('Couldn\'t remove', 'Check your connection and try again.');
        }
        return deleted;
      },
      child: row,
    );
  }
}

class _PaidToggle extends StatelessWidget {
  final bool paid;
  final VoidCallback onTap;
  const _PaidToggle({required this.paid, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: paid ? AppColor.income : AppColor.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: paid ? AppColor.income : AppColor.borderStrong,
                width: 1.5,
              ),
            ),
            child: Center(
              child: AnimatedScale(
                scale: paid ? 1 : 0.6,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: PhosphorIcon(
                  PhosphorIconsBold.check,
                  size: 14,
                  color: paid ? Colors.white : AppColor.textTertiary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      );
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
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.borderStrong),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColor.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: PhosphorIcon(PhosphorIconsDuotone.sparkle,
                      color: AppColor.warning, size: 20, duotoneSecondaryOpacity: 0.3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Looks like ${suggestion.merchantName} repeats',
                        style: AppTypography.bodySemiBold(AppColor.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '~$sym${fmt.format(suggestion.avgAmount)} ${suggestion.frequency} · seen ${suggestion.occurrences} times',
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
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    controller.dismissSuggestion(suggestion);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: AppColor.textSecondary,
                    side: const BorderSide(color: AppColor.borderStrong),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Not a bill', style: AppTypography.bodySemiBold(AppColor.textSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final ok = await controller.confirmSuggestion(suggestion);
                    if (!ok) {
                      CustomToast.errorToast('Couldn\'t add', 'Check your connection and try again.');
                      return;
                    }
                    showCelebration(CelebrationData(
                      title: 'Subscription tracked',
                      subtitle: '${suggestion.merchantName} · $sym${fmt.format(suggestion.avgAmount)}',
                      icon: PhosphorIconsDuotone.calendarCheck,
                      color: AppColor.warning,
                      footnote: 'We\'ll remind you before it\'s due.',
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Track it', style: AppTypography.bodySemiBold(Colors.white)),
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
  final Object icon;
  final Color color;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback? onAction;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    this.color = AppColor.primary,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 120),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Center(
                  child: PhosphorIcon(icon, color: color, size: 44,
                      duotoneSecondaryOpacity: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: AppTypography.heading3(AppColor.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppTypography.body(AppColor.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 22),
            if (onAction != null)
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onAction!();
                  },
                  icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 15, color: Colors.white),
                  label: Text(cta),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              )
            else
              Text(cta,
                  style: AppTypography.captionSemiBold(AppColor.primary),
                  textAlign: TextAlign.center),
          ],
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
    final sym = Get.find<HomeController>().currencySymbol.value;
    showCelebration(CelebrationData(
      title: 'Budget set',
      subtitle: '${_selectedCategory == 'All' ? 'Total spending' : _selectedCategory} · $sym${NumberFormat('#,##0', 'en_IN').format(amount)} ${_selectedPeriod}',
      icon: PhosphorIconsDuotone.shieldCheck,
      color: AppColor.catCar,
      footnote: 'We\'ll nudge you when you hit 80%.',
    ));
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
                        color: isSelected ? AppColor.primary : AppColor.surfaceVariant,
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
                      color: isSelected ? catColor.withValues(alpha: 0.10) : AppColor.surfaceVariant,
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
    final sym = Get.find<HomeController>().currencySymbol.value;
    showCelebration(CelebrationData(
      title: 'Goal created',
      subtitle: '$_selectedEmoji $name · $sym${NumberFormat('#,##0', 'en_IN').format(amount)}',
      icon: PhosphorIconsDuotone.target,
      color: AppColor.warning,
      footnote: 'Milestones at 25, 50, 75 and 100% — each one gets a celebration.',
    ));
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
                      color: isSelected ? AppColor.primary.withValues(alpha: 0.10) : AppColor.surfaceVariant,
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
    final ok = await widget.controller.addBillManually(merchantName: name, amount: amount, frequency: _frequency, dueDay: _dueDay);
    setState(() => _isSaving = false);
    if (!ok) {
      CustomToast.errorToast('Couldn\'t add', 'Check your connection and try again.');
      return;
    }
    if (mounted) Navigator.of(context).pop();
    showCelebration(CelebrationData(
      title: 'Subscription tracked',
      subtitle: '$name · due on day $_dueDay',
      icon: PhosphorIconsDuotone.calendarCheck,
      color: AppColor.warning,
      footnote: 'It\'ll show on your bills calendar every cycle.',
    ));
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
                      color: isSelected ? bg.withValues(alpha: 0.12) : AppColor.surfaceVariant,
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
                      color: selected ? AppColor.primary : AppColor.surfaceVariant,
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
  void _celebrateDeposit(double amount) {
    final g = widget.goal;
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0', 'en_IN');
    final before = g.targetAmount > 0 ? g.savedAmount / g.targetAmount : 0.0;
    final after = g.targetAmount > 0 ? (g.savedAmount + amount) / g.targetAmount : 0.0;
    final crossed = const [1.0, 0.75, 0.5, 0.25]
        .firstWhere((m) => before < m && after >= m, orElse: () => 0);
    final left = (g.targetAmount - g.savedAmount - amount).clamp(0.0, double.infinity);

    if (crossed == 1.0) {
      HapticFeedback.heavyImpact();
      showCelebration(CelebrationData(
        title: 'Goal reached!',
        subtitle: '${g.emoji} ${g.name} is fully funded',
        icon: PhosphorIconsDuotone.trophy,
        color: AppColor.income,
        footnote: 'You saved $sym${fmt.format(g.targetAmount)}. Time to enjoy it.',
      ));
    } else if (crossed > 0) {
      showCelebration(CelebrationData(
        title: '${(crossed * 100).round()}% milestone',
        subtitle: '${g.emoji} ${g.name} · $sym${fmt.format(g.savedAmount + amount)} saved',
        icon: PhosphorIconsDuotone.rocketLaunch,
        color: AppColor.primary,
        footnote: '$sym${fmt.format(left)} to go — keep it up.',
      ));
    } else {
      showCelebration(CelebrationData(
        title: '$sym${fmt.format(amount)} saved',
        subtitle: '${g.emoji} ${g.name} · ${(after * 100).clamp(0, 100).round()}% funded',
        icon: PhosphorIconsDuotone.piggyBank,
        color: AppColor.income,
        footnote: '$sym${fmt.format(left)} to go.',
      ));
    }
  }

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
    _celebrateDeposit(amount);
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
