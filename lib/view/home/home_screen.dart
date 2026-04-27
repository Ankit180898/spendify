import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/health_score_controller/health_score_controller.dart';
import 'package:spendify/controller/savings_controller/savings_controller.dart';
import 'package:spendify/controller/weekly_digest_controller/weekly_digest_controller.dart';
import 'package:spendify/view/health_score/health_score_screen.dart';
import 'package:spendify/view/weekly_digest/weekly_digest_screen.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/controller/walkthrough_controller.dart';
import 'package:spendify/model/savings_goal_model.dart';
import 'package:spendify/services/insights_service.dart';
import 'package:spendify/view/home/components/transaction_list.dart';
import 'package:spendify/view/wallet/add_transaction_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spendify/view/wallet/sms_import_screen.dart';
import 'package:spendify/view/splits/splits_screen.dart';
import 'package:spendify/view/goals/goals_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    if (!Get.isRegistered<TransactionController>())
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
          SliverToBoxAdapter(child: _InsightsStrip(isDark: isDark, ctrl: ctrl)),
          SliverToBoxAdapter(child: _WeeklyDigestBanner(isDark: isDark)),
          SliverToBoxAdapter(child: _HealthScoreCard(isDark: isDark)),
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
                        color: isDark
                            ? AppColor.darkCard
                            : const Color(0xFFF4F4F5),
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
                        color: isDark
                            ? AppColor.darkCard
                            : const Color(0xFFF4F4F5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          visible
                              ? PhosphorIconsLight.eye
                              : PhosphorIconsLight.eyeSlash,
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
                        visible
                            ? '${ctrl.currencySymbol.value}${fmt.format(ctrl.totalBalance.value)}'
                            : '${ctrl.currencySymbol.value}  ••••••',
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
                    value: visible
                        ? '${ctrl.currencySymbol.value}${_compact(ctrl.totalIncome.value)}'
                        : '•••',
                    color: AppColor.income,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    label: 'Expenses',
                    value: visible
                        ? '${ctrl.currencySymbol.value}${_compact(ctrl.totalExpense.value)}'
                        : '•••',
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
      if (ctrl.isOverviewLoading.value && ctrl.allTransactions.isEmpty) {
        return _MonthSummaryShimmer(isDark: isDark);
      }
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  value:
                      '${ctrl.currencySymbol.value}${fmt.format(monthIncome)}',
                  color: AppColor.income,
                  isDark: isDark,
                ),
                _MiniStat(
                  icon: PhosphorIconsLight.arrowDown,
                  label: 'Spent',
                  value:
                      '${ctrl.currencySymbol.value}${fmt.format(monthSpent)}',
                  color: AppColor.expense,
                  isDark: isDark,
                ),
                _MiniStat(
                  icon: PhosphorIconsLight.piggyBank,
                  label: saved >= 0 ? 'Saved' : 'Over',
                  value:
                      '${ctrl.currencySymbol.value}${fmt.format(saved.abs())}',
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
                  _QuickAction(
                    icon: PhosphorIconsLight.arrowCircleDown,
                    label: 'Expense',
                    color: AppColor.expense,
                    isDark: isDark,
                    onTap: () => Get.to(() =>
                        const AddTransactionScreen(initialType: 'expense')),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: PhosphorIconsLight.arrowCircleUp,
                    label: 'Income',
                    color: AppColor.income,
                    isDark: isDark,
                    onTap: () => Get.to(() =>
                        const AddTransactionScreen(initialType: 'income')),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: PhosphorIconsLight.usersThree,
                    label: 'Split',
                    color: AppColor.primary,
                    isDark: isDark,
                    onTap: () => Get.to(() => const SplitsScreen(),
                        transition: Transition.cupertino),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: PhosphorIconsLight.target,
                    label: 'Goals',
                    color: const Color(0xFFE87B35),
                    isDark: isDark,
                    onTap: () => showGoalsAddPicker(context),
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

// ─────────────────────────────────────────────────────────────────────────────
// Month summary shimmer skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _MonthSummaryShimmer extends StatelessWidget {
  final bool isDark;
  const _MonthSummaryShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF4F4F5);
    final highlight =
        isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE4E4E7);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6))),
                const Spacer(),
                Container(
                    height: 20,
                    width: 52,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 3 mini-stat boxes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(
                  3,
                  (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  height: 11,
                                  width: 50,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5))),
                              const SizedBox(height: 5),
                              Container(
                                  height: 13,
                                  width: 64,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5))),
                            ],
                          ),
                        ),
                      )),
            ),
          ),
          const SizedBox(height: 20),
          // Quick action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                    child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(width: 10),
                Expanded(
                    child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)))),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
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
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textMuted =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
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
                    color: barColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor:
                  isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7),
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
  final PhosphorIconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(icon, color: color, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insights shimmer skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsShimmer extends StatelessWidget {
  final bool isDark;
  const _InsightsShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF4F4F5);
    final highlight =
        isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE4E4E7);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Container(
                height: 14,
                width: 70,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6))),
          ),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => Container(
                width: 240,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: divColor),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insights strip — horizontally scrollable insight cards
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsStrip extends StatelessWidget {
  final bool isDark;
  final HomeController ctrl;
  const _InsightsStrip({required this.isDark, required this.ctrl});

  void _showInsightSheet(BuildContext context, Insight insight, bool isDark) {
    final bg = isDark ? AppColor.darkSurface : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final accent = insight.accentColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColor.darkBorder : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // emoji + badge row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(insight.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // full body text — no maxLines limit
            Text(
              insight.body,
              style: TextStyle(
                color: textMuted,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            // close button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Got it',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SavingsController? savingsCtrl;
    try {
      savingsCtrl = Get.find<SavingsController>();
    } catch (_) {}

    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);

    return Obx(() {
      if (ctrl.isOverviewLoading.value && ctrl.allTransactions.isEmpty) {
        return _InsightsShimmer(isDark: isDark);
      }

      final insights = InsightsService.compute(
        allTransactions: ctrl.allTransactions.toList(),
        monthlyBudget: ctrl.monthlyBudget.value,
        sym: ctrl.currencySymbol.value,
        savingsGoals: savingsCtrl?.goals.toList() ?? [],
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
            child: Row(
              children: [
                Text('Insights',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${insights.length}',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: insights.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final ins = insights[i];
                return GestureDetector(
                  onTap: () => _showInsightSheet(context, ins, isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ins.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: ins.accentColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ins.emoji,
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          ins.title,
                          style: TextStyle(
                            color: ins.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: divColor),
        ],
      );
    });
  }
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

  static PhosphorIconData _catIcon(String category) {
    switch (category) {
      case 'Food & Drinks':
        return PhosphorIconsLight.forkKnife;
      case 'Groceries':
        return PhosphorIconsLight.shoppingCart;
      case 'Transport':
        return PhosphorIconsLight.bus;
      case 'Car':
        return PhosphorIconsLight.car;
      case 'Shopping':
        return PhosphorIconsLight.bag;
      case 'Bills & Fees':
        return PhosphorIconsLight.lightning;
      case 'Health':
        return PhosphorIconsLight.pill;
      case 'Entertainment':
        return PhosphorIconsLight.filmSlate;
      case 'Travel':
        return PhosphorIconsLight.airplane;
      case 'Investments':
        return PhosphorIconsLight.trendUp;
      case 'Education':
        return PhosphorIconsLight.graduationCap;
      case 'Subscriptions':
        return PhosphorIconsLight.receipt;
      case 'Gifts':
        return PhosphorIconsLight.gift;
      case 'Others':
        return PhosphorIconsLight.tag;
      default:
        return PhosphorIconsLight.chartBar;
    }
  }

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
            final catColor = _catColors[g.category] ?? AppColor.primary;

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
                            child: PhosphorIcon(
                              _catIcon(g.category),
                              size: 15,
                              color: catColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            g.category == 'All' ? 'Total Spending' : g.category,
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
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
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
    final deadline = DateTime(
        goal.targetDate!.year, goal.targetDate!.month, goal.targetDate!.day);
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
          border: Border.all(
              color: urgencyColor.withValues(alpha: 0.35), width: 1.5),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

// ─────────────────────────────────────────────────────────────────────────────
// Financial Health Score card — compact home screen entry point
// ─────────────────────────────────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  final bool isDark;
  const _HealthScoreCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    HealthScoreController ctrl;
    try {
      ctrl = Get.find<HealthScoreController>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final trackColor = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);

    return Obx(() {
      final score = ctrl.score.value;

      if (score == null) {
        // Read HomeController observables inside Obx so this block re-runs
        // when loading finishes or allTransactions changes.
        HomeController? homeC;
        try {
          homeC = Get.find<HomeController>();
        } catch (_) {}

        final isLoading = homeC?.isOverviewLoading.value ?? true;
        final txCount = homeC?.allTransactions.length ?? 0;

        // Still fetching from Supabase — stay invisible, don't flash a wrong message
        if (isLoading || txCount >= 3) return const SizedBox.shrink();

        // Confirmed: data has loaded and user genuinely has fewer than 3 transactions
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: PhosphorIcon(
                        PhosphorIconsLight.heartbeat,
                        size: 16,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Health Score',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Log a few transactions to unlock your score',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: divColor),
          ],
        );
      }

      final change = ctrl.weeklyChange;
      final history = ctrl.history.toList();

      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Get.to(() => const HealthScoreScreen(),
              transition: Transition.cupertino);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(56, 56),
                          painter: _MiniArcPainter(
                            progress: score.total / 100,
                            color: score.levelColor,
                            trackColor: trackColor,
                          ),
                        ),
                        Text(
                          '${score.total}',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Financial Health',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            PhosphorIcon(
                              PhosphorIconsLight.caretRight,
                              size: 13,
                              color: textMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: score.levelColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                score.levelLabel,
                                style: TextStyle(
                                  color: score.levelColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (change != null) ...[
                              const SizedBox(width: 8),
                              PhosphorIcon(
                                change >= 0
                                    ? PhosphorIconsLight.trendUp
                                    : PhosphorIconsLight.trendDown,
                                size: 11,
                                color: change >= 0
                                    ? AppColor.income
                                    : AppColor.expense,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${change >= 0 ? '+' : ''}$change',
                                style: TextStyle(
                                  color: change >= 0
                                      ? AppColor.income
                                      : AppColor.expense,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (history.length > 1) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 16,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: history.map((h) {
                                final frac = h.total / 100;
                                final isLatest = h == history.last;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    child: Container(
                                      height: (frac * 12).clamp(2.0, 12.0),
                                      decoration: BoxDecoration(
                                        color: isLatest
                                            ? score.levelColor
                                            : score.levelColor
                                                .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: divColor),
          ],
        ),
      );
    });
  }
}

class _MiniArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _MiniArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  static const double _start = 135.0 * 3.14159265 / 180;
  static const double _sweep = 270.0 * 3.14159265 / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 5) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect, _start, _sweep, false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect, _start, _sweep * progress.clamp(0.0, 1.0), false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Digest Banner — shown Mon–Thu when last week's digest is ready
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyDigestBanner extends StatelessWidget {
  final bool isDark;
  const _WeeklyDigestBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    WeeklyDigestController? ctrl;
    try {
      ctrl = Get.find<WeeklyDigestController>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      if (!ctrl!.shouldShowBanner) return const SizedBox.shrink();
      final d = ctrl.digest.value!;
      final sym = Get.find<HomeController>().currencySymbol.value;
      final amt = d.totalSpent >= 1000
          ? '$sym${(d.totalSpent / 1000).toStringAsFixed(1)}K'
          : '$sym${d.totalSpent.toStringAsFixed(0)}';
      final cardBg = isDark ? AppColor.darkSurface : Colors.white;
      final border = isDark ? AppColor.darkBorder : const Color(0xFFE8E6E2);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Get.to(
          () => WeeklyDigestScreen(digest: d),
          transition: Transition.cupertino,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColor.primaryExtraSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIconsLight.chartBar,
                  color: AppColor.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week ${d.weekNumber} digest is ready',
                      style: TextStyle(
                        color: isDark
                            ? AppColor.textPrimary
                            : const Color(0xFF1A1916),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$amt spent · tap to see the full breakdown',
                      style: TextStyle(
                        color: isDark
                            ? AppColor.textSecondary
                            : const Color(0xFF6B6960),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsLight.arrowRight,
                    color: AppColor.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: ctrl.dismissBanner,
                    child: Icon(
                      PhosphorIconsLight.x,
                      color: isDark
                          ? AppColor.textSecondary
                          : const Color(0xFF9A9890),
                      size: 16,
                    ),
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
