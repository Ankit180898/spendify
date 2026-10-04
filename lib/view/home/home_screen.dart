import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/savings_controller/savings_controller.dart';
import 'package:spendify/controller/weekly_digest_controller/weekly_digest_controller.dart';
import 'package:spendify/view/weekly_digest/weekly_digest_screen.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/controller/walkthrough_controller.dart';
import 'package:spendify/model/savings_goal_model.dart';
import 'package:spendify/services/insights_service.dart';
import 'package:spendify/services/progress_service.dart';
import 'package:spendify/widgets/celebration.dart';
import 'package:spendify/view/home/components/transaction_list.dart';
import 'package:spendify/view/wallet/add_transaction_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spendify/view/wallet/sms_import_screen.dart';
import 'package:spendify/controller/groups_controller/groups_controller.dart';
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
            const SliverToBoxAdapter(child: _SplitsNudge()),
            const SliverToBoxAdapter(child: TransactionsContent(0)),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top section — period picker bar, promo-style balance banner, action grid
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

  void _pickPeriod(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
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
            const SizedBox(height: 18),
            const _SectionTitle('Show me'),
            const SizedBox(height: 8),
            ..._Period.values.map((p) {
              final active = p == period;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  onPeriodChange(p);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        p.label,
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? AppColor.primary : AppColor.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (active)
                        const PhosphorIcon(PhosphorIconsBold.check,
                            size: 16, color: AppColor.primary),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'morning' : now.hour < 17 ? 'afternoon' : 'evening';

    return Obx(() {
      final visible = ctrl.isAmountVisible.value;
      final name = ctrl.userName.value.split(' ').first;
      final sym = ctrl.currencySymbol.value;
      final balance = ctrl.totalBalance.value;
      final txs = ctrl.allTransactions.toList();
      final budget = ctrl.monthlyBudget.value;
      final progress = ProgressService.compute(
        transactions: txs,
        monthlyBudget: budget,
      );

      double spentOn(bool Function(DateTime d) test) => txs
          .where((t) {
            if (t['type'] != 'expense') return false;
            final d = DateTime.tryParse(t['date'] ?? '');
            return d != null && test(d);
          })
          .fold(0.0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0.0));

      final monthSpent = spentOn((d) => d.year == now.year && d.month == now.month);
      final last7 = List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        return spentOn((d) =>
            d.year == day.year && d.month == day.month && d.day == day.day);
      });

      return SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar: period picker (left) + actions (right) ──────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 14, 10),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pickPeriod(context),
                    child: Row(
                      children: [
                        const PhosphorIcon(PhosphorIconsLight.calendarBlank,
                            size: 20, color: AppColor.textPrimary),
                        const SizedBox(width: 8),
                        Text(
                          period.label,
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const PhosphorIcon(PhosphorIconsLight.caretDown,
                            size: 14, color: AppColor.textPrimary),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _BarIcon(
                    icon: visible ? PhosphorIconsLight.eye : PhosphorIconsLight.eyeSlash,
                    onTap: ctrl.toggleVisibility,
                  ),
                  _BarIcon(
                    icon: PhosphorIconsLight.chatCircleText,
                    onTap: () => Get.to(
                      () => const SmsImportScreen(),
                      transition: Transition.fadeIn,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColor.border),
            const SizedBox(height: 18),

            // ── Promo-style balance banner ───────────────────────────
            if (loading)
              const _BentoShimmer()
            else
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
                  borderRadius: BorderRadius.circular(18),
                ),
                child: _BalanceBanner(
                  greeting: name.isNotEmpty ? 'Good $greeting, $name' : 'Good $greeting',
                  periodLabel: period.label,
                  sym: sym,
                  balance: balance,
                  visible: visible,
                  income: income,
                  expense: expense,
                  monthSpent: monthSpent,
                  budget: budget,
                  last7: last7,
                ),
              ),

            // ── Streak & level ───────────────────────────────────────
            if (!loading) _ProgressCard(progress: progress),

            // ── Action grid ──────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: _SectionTitle('Quick actions'),
            ),
            Showcase(
              key: Get.find<WalkthroughController>().quickActionsKey,
              title: 'Log transactions fast',
              description: 'Tap to record an expense or income in seconds.',
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
              child: _ActionGrid(
                actions: [
                  _ActionItem(PhosphorIconsDuotone.arrowCircleUp, AppColor.expense, 'Expense',
                      () => Get.to(() => const AddTransactionScreen(initialType: 'expense'))),
                  _ActionItem(PhosphorIconsDuotone.arrowCircleDown, AppColor.income, 'Income',
                      () => Get.to(() => const AddTransactionScreen(initialType: 'income'))),
                  _ActionItem(PhosphorIconsDuotone.usersThree, AppColor.catCar, 'Split',
                      () => Get.to(() => const SplitsScreen(), transition: Transition.cupertino)),
                  _ActionItem(PhosphorIconsDuotone.target, AppColor.warning, 'Goal',
                      () => showGoalsAddPicker(context)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColor.heading,
          letterSpacing: -0.2,
        ),
      );
}

class _BarIcon extends StatelessWidget {
  final PhosphorIconData icon;
  final VoidCallback onTap;
  const _BarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        visualDensity: VisualDensity.compact,
        icon: PhosphorIcon(icon, color: AppColor.textPrimary, size: 22),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance banner — soft blush card, illustration cluster on the right
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceBanner extends StatelessWidget {
  final String greeting;
  final String periodLabel;
  final String sym;
  final double balance;
  final bool visible;
  final double income;
  final double expense;
  final double monthSpent;
  final double budget;
  final List<double> last7;

  const _BalanceBanner({
    required this.greeting,
    required this.periodLabel,
    required this.sym,
    required this.balance,
    required this.visible,
    required this.income,
    required this.expense,
    required this.monthSpent,
    required this.budget,
    required this.last7,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'en_IN');
    final net = income - expense;
    final isPositive = net >= 0;
    final netColor = isPositive ? AppColor.income : AppColor.expense;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
            decoration: BoxDecoration(
              color: AppColor.bannerBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColor.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Total balance',
                        style: GoogleFonts.urbanist(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textTertiary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: balance),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                        builder: (_, animated, __) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            visible ? '$sym${fmt.format(animated)}' : '$sym ••••••',
                            style: GoogleFonts.urbanist(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                              letterSpacing: -1.0,
                              height: 1.1,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColor.surface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              periodLabel,
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            PhosphorIcon(
                              isPositive
                                  ? PhosphorIconsBold.trendUp
                                  : PhosphorIconsBold.trendDown,
                              size: 12,
                              color: netColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              visible
                                  ? '${isPositive ? '+' : '−'}$sym${NumberFormat('#,##0', 'en_IN').format(net.abs())}'
                                  : '•••',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: netColor,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                budget > 0
                    ? _BudgetRing(spent: monthSpent, budget: budget)
                    : _WeekSparkline(values: last7),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FlowPill(
                  label: 'Income',
                  value: visible ? _fmt(income) : '•••',
                  icon: PhosphorIconsDuotone.arrowDownLeft,
                  color: AppColor.income,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FlowPill(
                  label: 'Spent',
                  value: visible ? _fmt(expense) : '•••',
                  icon: PhosphorIconsDuotone.arrowUpRight,
                  color: AppColor.expense,
                ),
              ),
            ],
          ),
          if (budget > 0) ...[
            const SizedBox(height: 10),
            _BudgetLine(spent: monthSpent, budget: budget, sym: sym, visible: visible),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '$sym${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '$sym${(v / 1000).toStringAsFixed(1)}K';
    return '$sym${NumberFormat('#,##0', 'en_IN').format(v)}';
  }
}

Color _budgetColor(double pct) => pct >= 1
    ? AppColor.expense
    : pct >= 0.8
        ? AppColor.warning
        : AppColor.income;

/// Month's budget used, drawn as an animated ring.
class _BudgetRing extends StatelessWidget {
  final double spent;
  final double budget;
  const _BudgetRing({required this.spent, required this.budget});

  @override
  Widget build(BuildContext context) {
    final pct = spent / budget;
    final color = _budgetColor(pct);
    return SizedBox(
      width: 92,
      height: 92,
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
                backgroundColor: AppColor.surface.withValues(alpha: 0.75),
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
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'of budget',
                  style: GoogleFonts.urbanist(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColor.textSecondary,
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

/// Last 7 days of spending as soft bars — shown when no budget is set.
class _WeekSparkline extends StatelessWidget {
  final List<double> values;
  const _WeekSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxV = values.fold(0.0, (m, v) => v > m ? v : m);
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '7-day spend',
            style: GoogleFonts.urbanist(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColor.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final h = maxV > 0 ? 6 + (values[i] / maxV) * 50 : 6.0;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 6, end: h),
                  duration: Duration(milliseconds: 500 + i * 60),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Container(
                    width: 8,
                    height: v,
                    decoration: BoxDecoration(
                      color: i == 6
                          ? AppColor.primary
                          : AppColor.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final d = today.subtract(Duration(days: 6 - i));
              return SizedBox(
                width: 8,
                child: Text(
                  days[d.weekday - 1],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.urbanist(
                    fontSize: 9,
                    color: AppColor.textTertiary,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BudgetLine extends StatelessWidget {
  final double spent;
  final double budget;
  final String sym;
  final bool visible;
  const _BudgetLine({
    required this.spent,
    required this.budget,
    required this.sym,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final pct = spent / budget;
    final left = budget - spent;
    final color = _budgetColor(pct);
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                !visible
                    ? '$sym•••'
                    : left >= 0
                        ? '$sym${fmt.format(left)} left'
                        : '$sym${fmt.format(-left)} over',
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: left >= 0 ? AppColor.textPrimary : AppColor.expense,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  visible ? 'of $sym${fmt.format(budget)} this month' : 'this month',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: AppColor.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
                style: GoogleFonts.urbanist(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: AppColor.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak & level card — tap for badges
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final UserProgress progress;
  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final subtitle = p.loggedToday
        ? 'Logged today · come back tomorrow'
        : p.streak > 0
            ? 'Log something today to keep it alive'
            : 'Log a transaction to start a streak';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _showBadges(context, p);
        },
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: p.streak > 0
                          ? const Color(0xFFE07A3F).withValues(alpha: 0.12)
                          : AppColor.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: PulsingFlame(size: 26, active: p.streak > 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.streak == 1 ? '1-day streak' : '${p.streak}-day streak',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: p.loggedToday || p.streak == 0
                                ? AppColor.textSecondary
                                : const Color(0xFFC0602E),
                            fontWeight: p.loggedToday ? FontWeight.w400 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColor.primaryExtraSoft,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PhosphorIcon(PhosphorIconsDuotone.medal,
                            size: 14, color: AppColor.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Lv ${p.level}',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _WeekDots(days: p.weekDays),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    p.levelTitle,
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${p.xp - p.levelStartXp} / ${p.nextLevelXp - p.levelStartXp} XP',
                    style: GoogleFonts.urbanist(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: p.levelProgress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    backgroundColor: AppColor.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation(AppColor.warning),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ...p.badges.where((b) => b.unlocked).take(5).map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: PhosphorIcon(b.icon, size: 18, color: b.color,
                              duotoneSecondaryOpacity: 0.3),
                        ),
                      ),
                  const SizedBox(width: 2),
                  Text(
                    '${p.unlockedCount}/${p.badges.length} badges',
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const PhosphorIcon(PhosphorIconsLight.caretRight,
                      size: 14, color: AppColor.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadges(BuildContext context, UserProgress p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, 24 + MediaQuery.of(context).padding.bottom),
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
            const SizedBox(height: 18),
            const _SectionTitle('Your badges'),
            const SizedBox(height: 4),
            Text(
              'Level ${p.level} ${p.levelTitle} · best streak ${p.bestStreak} days · ${p.totalLogged} logged',
              style: GoogleFonts.urbanist(fontSize: 12, color: AppColor.textSecondary),
            ),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.72,
              children: [
                for (var i = 0; i < p.badges.length; i++)
                  _BadgeTile(badge: p.badges[i], index: i),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Earn 10 XP per entry (up to 5 a day) plus 15 XP for every day you log.',
              style: GoogleFonts.urbanist(fontSize: 11, color: AppColor.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDots extends StatelessWidget {
  final List<bool> days;
  const _WeekDots({required this.days});

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIdx = DateTime.now().weekday - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final done = days[i];
        final isToday = i == todayIdx;
        final future = i > todayIdx;
        return Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: Duration(milliseconds: 350 + i * 50),
              curve: Curves.easeOutBack,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFFE07A3F)
                      : future
                          ? AppColor.surfaceVariant
                          : AppColor.surface,
                  shape: BoxShape.circle,
                  border: done || future
                      ? null
                      : Border.all(
                          color: isToday ? const Color(0xFFE07A3F) : AppColor.border,
                          width: isToday ? 1.5 : 1,
                        ),
                ),
                child: done
                    ? const Center(
                        child: PhosphorIcon(PhosphorIconsBold.check,
                            size: 14, color: Colors.white),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[i],
              style: GoogleFonts.urbanist(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? AppColor.textPrimary : AppColor.textTertiary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement badge;
  final int index;
  const _BadgeTile({required this.badge, required this.index});

  @override
  Widget build(BuildContext context) {
    final on = badge.unlocked;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 60),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: on ? badge.color.withValues(alpha: 0.12) : AppColor.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: on ? badge.color.withValues(alpha: 0.35) : AppColor.border,
                  ),
                ),
                child: Center(
                  child: PhosphorIcon(
                    badge.icon,
                    size: 28,
                    color: on ? badge.color : AppColor.textTertiary.withValues(alpha: 0.6),
                    duotoneSecondaryOpacity: 0.3,
                  ),
                ),
              ),
              if (!on)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.border),
                    ),
                    child: const Center(
                      child: PhosphorIcon(PhosphorIconsFill.lockSimple,
                          size: 10, color: AppColor.textTertiary),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.urbanist(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: on ? AppColor.textPrimary : AppColor.textTertiary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowPill extends StatelessWidget {
  final String label;
  final String value;
  final Object icon;
  final Color color;

  const _FlowPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColor.borderStrong),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(child: PhosphorIcon(icon, size: 15, color: color)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.urbanist(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textTertiary,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Action grid — ringed emoji circles, 4 per row
// ─────────────────────────────────────────────────────────────────────────────

class _ActionItem {
  final Object icon; // Phosphor duotone icon
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ActionItem(this.icon, this.color, this.label, this.onTap);
}

class _ActionGrid extends StatelessWidget {
  final List<_ActionItem> actions;
  const _ActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: actions
              .map((a) => Expanded(child: _ActionTile(item: a)))
              .toList(),
        ),
      );
}

class _ActionTile extends StatefulWidget {
  final _ActionItem item;
  const _ActionTile({required this.item});

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        item.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColor.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColor.borderStrong),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primary.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      item.icon,
                      size: 24,
                      color: item.color,
                      duotoneSecondaryOpacity: 0.28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.urbanist(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _BentoShimmer extends StatelessWidget {
  const _BentoShimmer();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColor.surfaceVariant,
        highlightColor: AppColor.border,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Insights strip
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsStrip extends StatelessWidget {
  final HomeController ctrl;
  const _InsightsStrip({required this.ctrl});

  static const _collapsed = 3;

  void _showDetail(BuildContext context, Insight insight) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + MediaQuery.of(context).padding.bottom),
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
                _InsightIcon(insight: insight, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(insight.title,
                      style: AppTypography.heading3(AppColor.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(insight.body, style: AppTypography.body(AppColor.textSecondary)),
            if (insight.progress != null) ...[
              const SizedBox(height: 16),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: insight.progress!.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: AppColor.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(insight.accentColor),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAll(BuildContext context, List<Insight> insights) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + MediaQuery.of(context).padding.bottom),
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
            const SizedBox(height: 18),
            const _SectionTitle('All insights'),
            const SizedBox(height: 12),
            _InsightsCard(
              insights: insights,
              onTap: (i) {
                Navigator.pop(sheetCtx);
                _showDetail(context, i);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SavingsController? savingsCtrl;
    if (Get.isRegistered<SavingsController>()) savingsCtrl = Get.find<SavingsController>();

    return Obx(() {
      if (ctrl.isOverviewLoading.value && ctrl.allTransactions.isEmpty) {
        return Shimmer.fromColors(
          baseColor: AppColor.surfaceVariant,
          highlightColor: AppColor.border,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.fromLTRB(20, 28, 12, 10),
            child: Row(
              children: [
                const _SectionTitle('Insights'),
                const Spacer(),
                if (insights.length > _collapsed)
                  TextButton(
                    onPressed: () => _showAll(context, insights),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('See all ${insights.length}',
                        style: AppTypography.captionSemiBold(AppColor.primary)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _InsightsCard(
              insights: insights.take(_collapsed).toList(),
              onTap: (i) => _showDetail(context, i),
            ),
          ),
        ],
      );
    });
  }
}

class _InsightsCard extends StatelessWidget {
  final List<Insight> insights;
  final ValueChanged<Insight> onTap;
  const _InsightsCard({required this.insights, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.borderStrong),
        ),
        child: Column(
          children: [
            for (var i = 0; i < insights.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: AppColor.border, indent: 66, endIndent: 14),
              InkWell(
                onTap: () => onTap(insights[i]),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    children: [
                      _InsightIcon(insight: insights[i]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insights[i].title,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (insights[i].stat != null)
                        Container(
                          constraints: const BoxConstraints(maxWidth: 96),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: insights[i].accentColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            insights[i].stat!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.captionSemiBold(insights[i].accentColor),
                          ),
                        )
                      else
                        const PhosphorIcon(PhosphorIconsLight.caretRight,
                            size: 14, color: AppColor.textTertiary),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

class _InsightIcon extends StatelessWidget {
  final Insight insight;
  final double size;
  const _InsightIcon({required this.insight, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: insight.accentColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: PhosphorIcon(insight.icon,
              size: size * 0.5,
              color: insight.accentColor,
              duotoneSecondaryOpacity: 0.3),
        ),
      );
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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: _SectionTitle('Budget Alerts'),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: _SectionTitle('Upcoming Deadlines'),
          ),
          ...urgent.map((g) => _UrgentGoalTile(goal: g)),
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

    final urgencyColor = daysLeft <= 0 ? AppColor.expense : daysLeft == 1 ? AppColor.warning : AppColor.primary;
    final urgencyLabel = daysLeft < 0
        ? 'Past due'
        : daysLeft == 0
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
          margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLG),
            border: Border.all(color: AppColor.border),
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

// ─────────────────────────────────────────────────────────────────────────────
// Splits nudge — compact strip shown only when there are unsettled balances
// ─────────────────────────────────────────────────────────────────────────────

class _SplitsNudge extends StatelessWidget {
  const _SplitsNudge();

  @override
  Widget build(BuildContext context) {
    final gc = Get.isRegistered<GroupsController>()
        ? Get.find<GroupsController>()
        : Get.put(GroupsController(), permanent: true);

    return Obx(() {
      final owed = gc.totalOwed.value;
      final owedToMe = gc.totalOwedToMe.value;
      final groups = gc.balanceGroupCount.value;

      if (owed == 0 && owedToMe == 0) return const SizedBox.shrink();

      final fmt = NumberFormat('#,##0', 'en_IN');

      final bool showOwed = owed > 0;
      final Color accent = showOwed ? AppColor.expense : AppColor.income;
      final Color bgColor = showOwed
          ? AppColor.expense.withValues(alpha: 0.07)
          : AppColor.income.withValues(alpha: 0.07);
      final Color borderColor = showOwed
          ? AppColor.expense.withValues(alpha: 0.2)
          : AppColor.income.withValues(alpha: 0.2);

      String label;
      if (owed > 0 && owedToMe > 0) {
        label =
            'You owe ₹${fmt.format(owed)}  ·  owed ₹${fmt.format(owedToMe)}';
      } else if (owed > 0) {
        label = 'You owe ₹${fmt.format(owed)} across $groups group${groups == 1 ? '' : 's'}';
      } else {
        label = 'You\'re owed ₹${fmt.format(owedToMe)} across $groups group${groups == 1 ? '' : 's'}';
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: GestureDetector(
          onTap: () => Get.to(
            () => const SplitsScreen(),
            transition: Transition.cupertino,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      showOwed
                          ? PhosphorIconsLight.arrowUp
                          : PhosphorIconsLight.arrowDown,
                      size: 14,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.urbanist(
                      color: AppColor.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const PhosphorIcon(
                  PhosphorIconsLight.caretRight,
                  size: 14,
                  color: AppColor.textTertiary,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
