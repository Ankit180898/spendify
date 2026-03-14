import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/savings_controller/savings_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/controller/walkthrough_controller.dart';
import 'package:spendify/model/savings_goal_model.dart';
import 'package:spendify/view/home/components/transaction_list.dart';
import 'package:spendify/view/wallet/add_transaction_screen.dart';
import 'package:spendify/view/wallet/sms_import_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(HomeController());
    Get.put(TransactionController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: isDark ? AppColor.darkBg : Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Header(isDark: isDark, ctrl: ctrl)),
          SliverToBoxAdapter(child: _MonthSummary(isDark: isDark, ctrl: ctrl)),
          SliverToBoxAdapter(child: _BudgetAlertsBanner(isDark: isDark)),
          SliverToBoxAdapter(child: _UrgentGoalsBanner(isDark: isDark)),
          const SliverToBoxAdapter(child: TransactionsContent(0)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — greeting, balance, visibility toggle
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isDark;
  final HomeController ctrl;
  const _Header({required this.isDark, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);
    final fmt = NumberFormat('#,##0.##', 'en_IN');
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return SafeArea(
      bottom: false,
      child: Obx(() {
        final name = ctrl.userName.value;
        final first = name.split(' ').first;
        final visible = ctrl.isAmountVisible.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first.isEmpty ? greeting : '$greeting, $first',
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your finances',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // SMS scan button (Android only)
                  GestureDetector(
                    onTap: () => Get.to(() => const SmsImportScreen(),
                        transition: Transition.fadeIn),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkCard : const Color(0xFFF4F4F5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          PhosphorIconsLight.chatCircleText,
                          color: textMuted,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: ctrl.toggleVisibility,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkCard : const Color(0xFFF4F4F5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          visible ? PhosphorIconsLight.eye : PhosphorIconsLight.eyeSlash,
                          color: textMuted,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Showcase(
              key: Get.find<WalkthroughController>().balanceKey,
              title: 'Your financial overview',
              description:
                  'See your total balance, income, and expenses at a glance. Tap the eye to hide amounts.',
              tooltipBackgroundColor: AppColor.primary,
              textColor: Colors.white,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              descTextStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
              targetShapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total balance',
                        style: TextStyle(color: textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        key: ValueKey(visible),
                        visible ? '${ctrl.currencySymbol.value}${fmt.format(ctrl.totalBalance.value)}' : '${ctrl.currencySymbol.value}  ••••••',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2.0,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  _StatPill(
                    label: 'Income',
                    value: visible ? '${ctrl.currencySymbol.value}${_compact(ctrl.totalIncome.value)}' : '•••',
                    color: AppColor.income,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    label: 'Expenses',
                    value: visible ? '${ctrl.currencySymbol.value}${_compact(ctrl.totalExpense.value)}' : '•••',
                    color: AppColor.expense,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(height: 1, color: divColor),
          ],
        );
      }),
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return NumberFormat('#,##0', 'en_IN').format(v);
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Month summary
// ─────────────────────────────────────────────────────────────────────────────

class _MonthSummary extends StatelessWidget {
  final bool isDark;
  final HomeController ctrl;
  const _MonthSummary({required this.isDark, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);
    final monthName = DateFormat('MMMM').format(DateTime.now());

    return Obx(() {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final thisMonthTx = ctrl.allTransactions.where((t) {
        try {
          return !DateTime.parse(t['date']).isBefore(monthStart);
        } catch (_) {
          return false;
        }
      }).toList();

      final monthSpent = thisMonthTx
          .where((t) => t['type'] == 'expense')
          .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
      final monthIncome = thisMonthTx
          .where((t) => t['type'] == 'income')
          .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
      final saved = monthIncome - monthSpent;
      final fmt = NumberFormat('#,##0', 'en_IN');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Text('$monthName overview',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.darkCard : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${thisMonthTx.length} txns',
                    style: TextStyle(color: textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _MiniStat(
                  icon: PhosphorIconsLight.arrowUp,
                  label: 'Earned',
                  value: '${ctrl.currencySymbol.value}${fmt.format(monthIncome)}',
                  color: AppColor.income,
                  isDark: isDark,
                ),
                _MiniStat(
                  icon: PhosphorIconsLight.arrowDown,
                  label: 'Spent',
                  value: '${ctrl.currencySymbol.value}${fmt.format(monthSpent)}',
                  color: AppColor.expense,
                  isDark: isDark,
                ),
                _MiniStat(
                  icon: PhosphorIconsLight.piggyBank,
                  label: saved >= 0 ? 'Saved' : 'Over',
                  value: '${ctrl.currencySymbol.value}${fmt.format(saved.abs())}',
                  color: saved >= 0 ? AppColor.income : AppColor.expense,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          // ── Monthly budget bar ──────────────────────────────
          if (ctrl.monthlyBudget.value > 0) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _BudgetBar(
                spent: monthSpent,
                budget: ctrl.monthlyBudget.value,
                sym: ctrl.currencySymbol.value,
                isDark: isDark,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Showcase(
            key: Get.find<WalkthroughController>().quickActionsKey,
            title: 'Log transactions fast',
            description:
                'Tap to record an expense or income in seconds, with categories and notes.',
            tooltipBackgroundColor: AppColor.primary,
            textColor: Colors.white,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            descTextStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.5,
            ),
            targetShapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      label: 'Add expense',
                      color: AppColor.expense,
                      onTap: () => Get.to(() => const AddTransactionScreen(initialType: 'expense')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      label: 'Add income',
                      color: AppColor.income,
                      onTap: () => Get.to(() => const AddTransactionScreen(initialType: 'income')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: divColor),
        ],
      );
    });
  }

}

class _BudgetBar extends StatelessWidget {
  final double spent;
  final double budget;
  final String sym;
  final bool isDark;

  const _BudgetBar({
    required this.spent,
    required this.budget,
    required this.sym,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (spent / budget).clamp(0.0, 1.0);
    final isOver = spent > budget;
    final barColor = isOver
        ? AppColor.expense
        : pct >= 0.8
            ? AppColor.warning
            : AppColor.income;
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textMuted = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final trackColor = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Monthly Budget',
                  style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                isOver
                    ? '$sym${fmt.format(spent - budget)} over'
                    : '$sym${fmt.format(budget - spent)} left',
                style: TextStyle(
                    color: barColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppColor.darkBorder
                  : const Color(0xFFE4E4E7),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('$sym${fmt.format(spent)} spent',
                  style: TextStyle(color: textMuted, fontSize: 11)),
              const Spacer(),
              Text('of $sym${fmt.format(budget)}',
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget limits banner — shows at-risk category limits (≥75% spent)
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetAlertsBanner extends StatelessWidget {
  final bool isDark;
  const _BudgetAlertsBanner({required this.isDark});

  static const _catColors = {
    'Food & Drinks': Color(0xFFEAB308),
    'Groceries': Color(0xFF22C55E),
    'Transport': Color(0xFF8B5CF6),
    'Bills & Fees': Color(0xFFF97316),
    'Health': Color(0xFFEF4444),
    'Car': Color(0xFF6366F1),
    'Shopping': Color(0xFFEC4899),
    'Entertainment': Color(0xFF14B8A6),
    'Investments': Color(0xFF3B82F6),
    'Education': Color(0xFF8B5CF6),
    'Travel': Color(0xFF06B6D4),
    'Gifts': Color(0xFFFF7849),
    'Subscriptions': Color(0xFFA855F7),
    'Others': Color(0xFF71717A),
    'All': AppColor.primary,
  };

  @override
  Widget build(BuildContext context) {
    GoalsController goalsCtrl;
    try {
      goalsCtrl = Get.find<GoalsController>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final trackColor = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Obx(() {
      final atRisk = goalsCtrl.goals.where((g) {
        final spent = goalsCtrl.currentSpending(g);
        return g.limitAmount > 0 && spent / g.limitAmount >= 0.75;
      }).toList()
        ..sort((a, b) {
          final pa = goalsCtrl.currentSpending(a) / a.limitAmount;
          final pb = goalsCtrl.currentSpending(b) / b.limitAmount;
          return pb.compareTo(pa); // highest % first
        });

      if (atRisk.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('Budget Alerts',
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          ...atRisk.map((g) {
            final spent = goalsCtrl.currentSpending(g);
            final pct = (spent / g.limitAmount).clamp(0.0, 1.0);
            final isOver = spent >= g.limitAmount;
            final barColor = isOver
                ? AppColor.expense
                : pct >= 0.9
                    ? AppColor.warning
                    : AppColor.income;
            final catColor =
                _catColors[g.category] ?? AppColor.primary;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: barColor.withValues(alpha: 0.35), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              g.category == 'All' ? '📊' : '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            g.category == 'All'
                                ? 'Total Spending'
                                : g.category,
                            style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: barColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            isOver
                                ? 'Over limit'
                                : '${(pct * 100).toInt()}% used',
                            style: TextStyle(
                                color: barColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: trackColor,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '$sym${fmt.format(spent)} spent',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          'of $sym${fmt.format(g.limitAmount)} ${g.period}',
                          style: TextStyle(
                              color: textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Divider(height: 1, color: divColor),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Urgent savings goals banner
// ─────────────────────────────────────────────────────────────────────────────

class _UrgentGoalsBanner extends StatelessWidget {
  final bool isDark;
  const _UrgentGoalsBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    SavingsController savingsCtrl;
    try {
      savingsCtrl = Get.find<SavingsController>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);

    return Obx(() {
      final goals = savingsCtrl.goals.toList(); // trigger reactivity
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final urgent = goals.where((g) {
        if (g.targetDate == null) return false;
        if (g.savedAmount >= g.targetAmount) return false;
        final deadline = DateTime(
            g.targetDate!.year, g.targetDate!.month, g.targetDate!.day);
        final daysLeft = deadline.difference(today).inDays;
        return daysLeft >= 0 && daysLeft <= 7;
      }).toList()
        ..sort((a, b) {
          final da = DateTime(
              a.targetDate!.year, a.targetDate!.month, a.targetDate!.day);
          final db = DateTime(
              b.targetDate!.year, b.targetDate!.month, b.targetDate!.day);
          return da.compareTo(db);
        });

      if (urgent.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('Upcoming Deadlines',
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          ...urgent.map((g) => _UrgentGoalTile(goal: g, isDark: isDark)),
          const SizedBox(height: 8),
          Divider(height: 1, color: divColor),
        ],
      );
    });
  }
}

class _UrgentGoalTile extends StatelessWidget {
  final SavingsGoal goal;
  final bool isDark;
  const _UrgentGoalTile({required this.goal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final trackColor = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0', 'en_IN');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(goal.targetDate!.year, goal.targetDate!.month, goal.targetDate!.day);
    final daysLeft = deadline.difference(today).inDays;

    final urgencyColor = daysLeft == 0
        ? AppColor.expense
        : daysLeft == 1
            ? AppColor.warning
            : AppColor.primary;

    final urgencyLabel = daysLeft == 0
        ? 'Due today'
        : daysLeft == 1
            ? 'Due tomorrow'
            : '$daysLeft days left';

    final pct = (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
    final remaining = goal.targetAmount - goal.savedAmount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: urgencyColor.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(goal.name,
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(urgencyLabel,
                      style: TextStyle(
                          color: urgencyColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${(pct * 100).toInt()}% funded',
                    style: TextStyle(color: textMuted, fontSize: 11)),
                const Spacer(),
                Text('$sym${fmt.format(remaining)} to go',
                    style: TextStyle(
                        color: urgencyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
