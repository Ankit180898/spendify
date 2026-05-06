import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
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

// ─────────────────────────────────────────────────────────────────────────────
// Time filter config
// ─────────────────────────────────────────────────────────────────────────────
enum _Period { today, week, month, year }

extension _PeriodLabel on _Period {
  String get label {
    switch (this) {
      case _Period.today:
        return 'Today';
      case _Period.week:
        return 'This Week';
      case _Period.month:
        return 'This Month';
      case _Period.year:
        return 'This Year';
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Period _period = _Period.month;

  HomeController get _ctrl {
    final c = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    if (!Get.isRegistered<TransactionController>()) {
      Get.put(TransactionController());
    }
    return c;
  }

  DateTimeRange _range(_Period p) {
    final now = DateTime.now();
    switch (p) {
      case _Period.today:
        final s = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: s, end: now);
      case _Period.week:
        final s = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(s.year, s.month, s.day),
          end: now,
        );
      case _Period.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case _Period.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColor.bg,
      body: Obx(() {
        final range = _range(_period);
        final filtered = ctrl.allTransactions.where((t) {
          final d = DateTime.tryParse(t['date'] ?? '');
          if (d == null) return false;
          return !d.isBefore(range.start) && !d.isAfter(range.end);
        }).toList();

        final income = filtered
            .where((t) => t['type'] == 'income')
            .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
        final expense = filtered
            .where((t) => t['type'] == 'expense')
            .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _TopSection(
                ctrl: ctrl,
                period: _period,
                onPeriodChange: (p) => setState(() => _period = p),
                income: income,
                expense: expense,
                loading: ctrl.isOverviewLoading.value && ctrl.allTransactions.isEmpty,
              ),
            ),
            SliverToBoxAdapter(child: _InsightsStrip(ctrl: ctrl)),
            const SliverToBoxAdapter(child: _WeeklyDigestBanner()),
            const SliverToBoxAdapter(child: _BudgetAlertsBanner()),
            const SliverToBoxAdapter(child: _UrgentGoalsBanner()),
            const SliverToBoxAdapter(child: TransactionsContent(0)),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top section — greeting, filter pills, bento grid, quick actions
// ─────────────────────────────────────────────────────────────────────────────

class _TopSection extends StatelessWidget {
  final HomeController ctrl;
  final _Period period;
  final ValueChanged<_Period> onPeriodChange;
  final double income;
  final double expense;
  final bool loading;

  const _TopSection({
    required this.ctrl,
    required this.period,
    required this.onPeriodChange,
    required this.income,
    required this.expense,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'morning' : now.hour < 17 ? 'afternoon' : 'evening';

    return Obx(() {
      final visible = ctrl.isAmountVisible.value;
      final name = ctrl.userName.value.split(' ').first;
      final sym = ctrl.currencySymbol.value;
      final balance = ctrl.totalBalance.value;

      return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.to(
                    () => const SmsImportScreen(),
                    transition: Transition.fadeIn,
                  ),
                  child: const _IconPill(icon: PhosphorIconsLight.chatCircleText),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: ctrl.toggleVisibility,
                  child: _IconPill(
                    icon: visible
                        ? PhosphorIconsLight.eye
                        : PhosphorIconsLight.eyeSlash,
                  ),
                ),
              ],
            ),
          ),

          // ── Greeting ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good $greeting',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColor.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  name.isNotEmpty ? '$name 👋' : 'Hello 👋',
                  style: GoogleFonts.urbanist(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                    letterSpacing: -0.8,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('EEEE, MMM d').format(now),
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColor.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // ── Time filter pills ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _Period.values.map((p) {
                  final active = p == period;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onPeriodChange(p);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppColor.primary : AppColor.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: active ? AppColor.primary : AppColor.border,
                        ),
                      ),
                      child: Text(
                        p.label,
                        style: TextStyle(
                          color: active ? Colors.white : AppColor.textSecondary,
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Bento grid ────────────────────────────────────────
          if (loading)
            const _BentoShimmer()
          else ...[
            // Balance card — full width, Vanilla
            Showcase(
              key: Get.find<WalkthroughController>().balanceKey,
              title: 'Your financial overview',
              description:
                  'See your total balance, income, and expenses. Tap the eye to hide amounts.',
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
                borderRadius: BorderRadius.circular(24),
              ),
              child: _BalanceCard(
                sym: sym,
                balance: balance,
                visible: visible,
                net: income - expense,
                transactions: ctrl.allTransactions.toList(),
              ),
            ),
            const SizedBox(height: 10),
            // Income + Expense row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatBentoCell(
                      label: 'Income',
                      value: visible ? _fmt(income, sym) : '•••',
                      icon: PhosphorIconsLight.arrowCircleDown,
                      iconColor: AppColor.income,
                      bg: AppColor.incomeSoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBentoCell(
                      label: 'Expenses',
                      value: visible ? _fmt(expense, sym) : '•••',
                      icon: PhosphorIconsLight.arrowCircleUp,
                      iconColor: AppColor.expense,
                      bg: AppColor.expenseSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Quick actions ─────────────────────────────────────
          Showcase(
            key: Get.find<WalkthroughController>().quickActionsKey,
            title: 'Log transactions fast',
            description:
                'Tap to record an expense or income in seconds.',
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickAction(
                    icon: PhosphorIconsLight.arrowCircleUp,
                    label: 'Expense',
                    accentColor: AppColor.expense,
                    onTap: () => Get.to(
                        () => const AddTransactionScreen(initialType: 'expense')),
                  ),
                  _QuickAction(
                    icon: PhosphorIconsLight.arrowCircleDown,
                    label: 'Income',
                    accentColor: AppColor.income,
                    onTap: () => Get.to(
                        () => const AddTransactionScreen(initialType: 'income')),
                  ),
                  _QuickAction(
                    icon: PhosphorIconsLight.usersThree,
                    label: 'Split',
                    accentColor: AppColor.catCar,
                    onTap: () => Get.to(
                      () => const SplitsScreen(),
                      transition: Transition.cupertino,
                    ),
                  ),
                  _QuickAction(
                    icon: PhosphorIconsLight.target,
                    label: 'Goals',
                    accentColor: AppColor.warning,
                    onTap: () => showGoalsAddPicker(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColor.border),
        ],
      ),
    );
    });
  }

  String _fmt(double v, String sym) {
    if (v >= 100000) return '$sym${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '$sym${(v / 1000).toStringAsFixed(1)}K';
    return '$sym${NumberFormat('#,##0', 'en_IN').format(v)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon pill button (top bar)
// ─────────────────────────────────────────────────────────────────────────────

class _IconPill extends StatelessWidget {
  final PhosphorIconData icon;
  const _IconPill({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColor.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColor.border),
        ),
        child: Center(
          child: PhosphorIcon(icon, color: AppColor.textSecondary, size: 16),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance card — Vanilla background, large number
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final String sym;
  final double balance;
  final bool visible;
  final double net;
  final List<Map<String, dynamic>> transactions;

  const _BalanceCard({
    required this.sym,
    required this.balance,
    required this.visible,
    required this.net,
    required this.transactions,
  });

  List<double> _last7DayExpenses() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return transactions
          .where((t) {
            if (t['type'] != 'expense') return false;
            final d = DateTime.tryParse(t['date'] ?? '');
            if (d == null) return false;
            return d.year == day.year && d.month == day.month && d.day == day.day;
          })
          .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'en_IN');
    final isPositive = net >= 0;
    final bars = _last7DayExpenses();
    final maxBar = bars.reduce(math.max);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColor.accentYellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColor.textPrimary.withValues(alpha: 0.50),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        key: ValueKey(visible),
                        child: Text(
                          visible ? '$sym${fmt.format(balance)}' : '$sym ••••••',
                          style: GoogleFonts.urbanist(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                            letterSpacing: -1.2,
                            height: 1.1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 7-day spending pulse
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '7-day spend',
                    style: GoogleFonts.urbanist(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textPrimary.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final isToday = i == 6;
                      final h = maxBar > 0 ? 4.0 + (bars[i] / maxBar) * 20.0 : 4.0;
                      return Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Container(
                          width: 4,
                          height: h,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColor.textPrimary.withValues(alpha: 0.75)
                                : AppColor.textPrimary.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                isPositive ? PhosphorIconsLight.trendUp : PhosphorIconsLight.trendDown,
                size: 13,
                color: isPositive ? AppColor.income : AppColor.expense,
              ),
              const SizedBox(width: 5),
              Text(
                visible
                    ? '${isPositive ? '+' : '−'}${NumberFormat('#,##0', 'en_IN').format(net.abs())} this period'
                    : '•••',
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColor.income : AppColor.expense,
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
// Stat bento cell — Income / Expense side by side
// ─────────────────────────────────────────────────────────────────────────────

class _StatBentoCell extends StatelessWidget {
  final String label;
  final String value;
  final PhosphorIconData icon;
  final Color iconColor;
  final Color bg;

  const _StatBentoCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(icon, color: iconColor, size: 14),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.urbanist(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick action — dark circle + label
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentColor = AppColor.primary,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(icon, color: accentColor, size: 22),
              ),
            ),
            const SizedBox(height: 6),
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
// Bento shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _BentoShimmer extends StatelessWidget {
  const _BentoShimmer();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColor.surfaceVariant,
        highlightColor: AppColor.border,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 66,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 66,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Insights strip
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsStrip extends StatelessWidget {
  final HomeController ctrl;
  const _InsightsStrip({required this.ctrl});

  void _showSheet(BuildContext context, Insight insight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: const BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: AppColor.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: insight.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(insight.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(insight.title,
                      style: AppTypography.heading3(AppColor.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(insight.body,
                style: AppTypography.body(AppColor.textSecondary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Got it',
                    style: AppTypography.bodySemiBold(insight.accentColor)),
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

    return Obx(() {
      if (ctrl.isOverviewLoading.value && ctrl.allTransactions.isEmpty) {
        return Shimmer.fromColors(
          baseColor: AppColor.surfaceVariant,
          highlightColor: AppColor.border,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: List.generate(
                2,
                (i) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      final insights = InsightsService.compute(
        allTransactions: ctrl.allTransactions.toList(),
        monthlyBudget: ctrl.monthlyBudget.value,
        sym: ctrl.currencySymbol.value,
        savingsGoals: savingsCtrl?.goals.toList() ?? [],
      );

      if (insights.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text(
              'INSIGHTS',
              style: GoogleFonts.urbanist(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColor.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: insights.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final ins = insights[i];
                return GestureDetector(
                  onTap: () => _showSheet(context, ins),
                  child: Container(
                    width: 210,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: ins.accentColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ins.accentColor.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      children: [
                        Text(ins.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ins.title,
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColor.textPrimary,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColor.border),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget alerts banner
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetAlertsBanner extends StatelessWidget {
  const _BudgetAlertsBanner();

  static PhosphorIconData _catIcon(String cat) {
    switch (cat) {
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
      default:
        return PhosphorIconsLight.tag;
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
          return pb.compareTo(pa);
        });

      if (atRisk.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Text('Budget Alerts',
                style: AppTypography.heading3(AppColor.textPrimary)),
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
            final catColor = AppColor.categoryColor(g.category);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                  border: Border.all(
                      color: barColor.withValues(alpha: 0.35), width: 1.5),
                  boxShadow: AppShadows.cardLight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: PhosphorIcon(_catIcon(g.category),
                                size: 15, color: catColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            g.category == 'All' ? 'Total Spending' : g.category,
                            style: AppTypography.bodySemiBold(AppColor.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: barColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            isOver
                                ? 'Over limit'
                                : '${(pct * 100).toInt()}% used',
                            style: AppTypography.captionSemiBold(barColor),
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
                        backgroundColor: AppColor.border,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('$sym${fmt.format(spent)} spent',
                            style: AppTypography.caption(AppColor.textSecondary)),
                        const Spacer(),
                        Text('of $sym${fmt.format(g.limitAmount)} ${g.period}',
                            style: AppTypography.captionSemiBold(
                                AppColor.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColor.border),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Urgent savings goals banner
// ─────────────────────────────────────────────────────────────────────────────

class _UrgentGoalsBanner extends StatelessWidget {
  const _UrgentGoalsBanner();

  @override
  Widget build(BuildContext context) {
    SavingsController savingsCtrl;
    try {
      savingsCtrl = Get.find<SavingsController>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final goals = savingsCtrl.goals.toList();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final urgent = goals.where((g) {
        if (g.targetDate == null) return false;
        if (g.savedAmount >= g.targetAmount) return false;
        final deadline = DateTime(
            g.targetDate!.year, g.targetDate!.month, g.targetDate!.day);
        return deadline.difference(today).inDays.clamp(0, 999) <= 7;
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Text('Upcoming Deadlines',
                style: AppTypography.heading3(AppColor.textPrimary)),
          ),
          ...urgent.map((g) => _UrgentGoalTile(goal: g)),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColor.border),
        ],
      );
    });
  }
}

class _UrgentGoalTile extends StatelessWidget {
  final SavingsGoal goal;
  const _UrgentGoalTile({required this.goal});

  @override
  Widget build(BuildContext context) {
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
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          border: Border.all(
              color: urgencyColor.withValues(alpha: 0.35), width: 1.5),
          boxShadow: AppShadows.cardLight,
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
                      style: AppTypography.bodySemiBold(AppColor.textPrimary)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(urgencyLabel,
                      style: AppTypography.captionSemiBold(urgencyColor)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: AppColor.border,
                valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${(pct * 100).toInt()}% funded',
                    style: AppTypography.caption(AppColor.textSecondary)),
                const Spacer(),
                Text('$sym${fmt.format(remaining)} to go',
                    style: AppTypography.captionSemiBold(urgencyColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Digest Banner
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyDigestBanner extends StatelessWidget {
  const _WeeklyDigestBanner();

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

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Get.to(() => WeeklyDigestScreen(digest: d),
            transition: Transition.cupertino),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLG),
            border: Border.all(color: AppColor.border),
            boxShadow: AppShadows.cardLight,
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
                child: const Icon(PhosphorIconsLight.chartBar,
                    color: AppColor.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Week ${d.weekNumber} digest is ready',
                        style:
                            AppTypography.bodySemiBold(AppColor.textPrimary)),
                    const SizedBox(height: 2),
                    Text('$amt spent · tap to see breakdown',
                        style: AppTypography.caption(AppColor.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(PhosphorIconsLight.arrowRight,
                      color: AppColor.primary, size: 16),
                  const SizedBox(width: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: ctrl.dismissBanner,
                    child: const Icon(PhosphorIconsLight.x,
                        color: AppColor.textTertiary, size: 16),
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
