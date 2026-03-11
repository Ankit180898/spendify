import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/transaction_details_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _month;
  bool _showBar = false;
  String _viewType = 'expense';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _prevMonth() {
    HapticFeedback.lightImpact();
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _fadeCtrl
      ..reset()
      ..forward();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    HapticFeedback.lightImpact();
    setState(() => _month = DateTime(_month.year, _month.month + 1));
    _fadeCtrl
      ..reset()
      ..forward();
  }

  List<Map<String, dynamic>> _txForMonth(
      List<Map<String, dynamic>> all, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return all.where((t) {
      final d = DateTime.parse(t['date']);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  double _sum(List<Map<String, dynamic>> list, String type) => list
      .where((t) => t['type'] == type)
      .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

  Map<String, double> _categoryTotals(
      List<Map<String, dynamic>> list, String type) {
    final Map<String, double> out = {};
    for (final t in list) {
      if (t['type'] != type) continue;
      final cat = t['category'];
      if (cat == null || (cat as String).isEmpty) continue;
      out[cat] = (out[cat] ?? 0) + (t['amount'] as num).toDouble();
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : AppColor.lightBg;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            final controller = Get.find<HomeController>();
            final all = controller.allTransactions;
            final monthTx = _txForMonth(all, _month);
            final income = _sum(monthTx, 'income');
            final spent = _sum(monthTx, 'expense');
            final net = income - spent;
            final cats = _categoryTotals(monthTx, _viewType);
            final total = _viewType == 'expense' ? spent : income;
            final sorted = cats.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return RefreshIndicator(
              color: AppColor.primary,
              backgroundColor:
                  isDark ? AppColor.darkCard : AppColor.lightSurface,
              onRefresh: () async =>
                  await Future.delayed(const Duration(milliseconds: 600)),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _TopBar(
                        month: _month,
                        isDark: isDark,
                        onPrev: _prevMonth,
                        onNext: _nextMonth,
                        canGoNext: !(_month.year == DateTime.now().year &&
                            _month.month == DateTime.now().month),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _HeroCard(
                        spent: spent,
                        income: income,
                        net: net,
                        isDark: isDark,
                        month: _month,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _SectionLabel(label: 'Breakdown', isDark: isDark),
                    ),
                    SliverToBoxAdapter(
                      child: _BreakdownCard(
                        sorted: sorted,
                        total: total,
                        viewType: _viewType,
                        showBar: _showBar,
                        isDark: isDark,
                        onViewTypeChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _viewType = v);
                        },
                        onChartTypeChanged: (b) {
                          HapticFeedback.selectionClick();
                          setState(() => _showBar = b);
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _SectionLabel(
                        label: 'Transactions',
                        isDark: isDark,
                        trailing:
                            monthTx.isNotEmpty ? '${monthTx.length}' : null,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _TransactionsList(
                          monthTx: monthTx, isDark: isDark),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom +
                            AppDimens.navBarHeight +
                            AppDimens.spaceLG,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final DateTime month;
  final bool isDark;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const _TopBar({
    required this.month,
    required this.isDark,
    required this.onPrev,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final btnBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analytics', style: AppTypography.heading2(textPrimary)),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMMM yyyy').format(month),
                style: AppTypography.caption(textSecondary),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: btnBg,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
                _NavBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: canGoNext ? onNext : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Icon(icon,
              size: 17,
              color:
                  onTap != null ? AppColor.primary : AppColor.textTertiary),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  final String? trailing;

  const _SectionLabel(
      {required this.label, required this.isDark, this.trailing});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.captionSemiBold(textSecondary).copyWith(
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                trailing!,
                style: AppTypography.caption(AppColor.primary)
                    .copyWith(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero card — large spend + spend ratio ring + income/saved chips
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final double spent;
  final double income;
  final double net;
  final bool isDark;
  final DateTime month;

  const _HeroCard({
    required this.spent,
    required this.income,
    required this.net,
    required this.isDark,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final fmtCompact = NumberFormat.compactCurrency(
        symbol: '₹', decimalDigits: 1, locale: 'en_IN');
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final isPositive = net >= 0;
    final netColor = isPositive ? AppColor.income : AppColor.expense;
    final ratio = income > 0 ? (spent / income).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColor.expense.withValues(alpha: 0.07),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: big number + ring ─────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Spent',
                          style: AppTypography.caption(textSecondary)),
                      const SizedBox(height: 6),
                      Text(
                        '₹${fmt.format(spent)}',
                        style:
                            AppTypography.heading2(textPrimary).copyWith(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                _SpendRing(ratio: ratio, isDark: isDark),
              ],
            ),

            const SizedBox(height: 20),
            Divider(height: 1, thickness: 1, color: border),
            const SizedBox(height: 18),

            // ── Income + Net chips ─────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Income',
                    value: fmtCompact.format(income),
                    color: AppColor.income,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatChip(
                    icon: isPositive
                        ? Icons.savings_outlined
                        : Icons.warning_amber_rounded,
                    label: isPositive ? 'Saved' : 'Over budget',
                    value:
                        '${isPositive ? '+' : '-'}${fmtCompact.format(net.abs())}',
                    color: netColor,
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

class _SpendRing extends StatelessWidget {
  final double ratio;
  final bool isDark;

  const _SpendRing({required this.ratio, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);
    final ringColor =
        ratio > 0.85 ? AppColor.expense : AppColor.primary;

    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: 5.5,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(ratio * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: ringColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
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
// Breakdown card
// ─────────────────────────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  final String viewType;
  final bool showBar;
  final bool isDark;
  final ValueChanged<String> onViewTypeChanged;
  final ValueChanged<bool> onChartTypeChanged;

  const _BreakdownCard({
    required this.sorted,
    required this.total,
    required this.viewType,
    required this.showBar,
    required this.isDark,
    required this.onViewTypeChanged,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final btnBg = isDark ? AppColor.darkElevated : AppColor.lightBg;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColor.primary.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 0),
              child: Row(
                children: [
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: btnBg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SegPill(
                          label: 'Expenses',
                          selected: viewType == 'expense',
                          color: AppColor.expense,
                          isDark: isDark,
                          onTap: () => onViewTypeChanged('expense'),
                        ),
                        _SegPill(
                          label: 'Income',
                          selected: viewType == 'income',
                          color: AppColor.income,
                          isDark: isDark,
                          onTap: () => onViewTypeChanged('income'),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: btnBg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        _IconToggle(
                          icon: Icons.donut_large_rounded,
                          selected: !showBar,
                          onTap: () => onChartTypeChanged(false),
                        ),
                        _IconToggle(
                          icon: Icons.bar_chart_rounded,
                          selected: showBar,
                          onTap: () => onChartTypeChanged(true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (sorted.isEmpty)
              _EmptyChart(isDark: isDark)
            else ...[
              showBar
                  ? _BarChart(
                      sorted: sorted,
                      isDark: isDark,
                      textPrimary: textPrimary)
                  : _DonutChart(
                      total: total,
                      sorted: sorted,
                      viewType: viewType,
                      isDark: isDark),
              Divider(
                  height: 1,
                  thickness: 1,
                  color: border,
                  indent: 16,
                  endIndent: 16),
              _CategoryRows(sorted: sorted, total: total, isDark: isDark),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SegPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _SegPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: selected
              ? AppTypography.captionSemiBold(color).copyWith(fontSize: 11)
              : AppTypography.label(textSecondary).copyWith(fontSize: 11),
        ),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _IconToggle(
      {required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColor.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Icon(icon,
              size: 16,
              color: selected ? AppColor.primary : AppColor.textTertiary),
        ),
      );
}

class _EmptyChart extends StatelessWidget {
  final bool isDark;
  const _EmptyChart({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 40,
                color: AppColor.textTertiary.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text('No data for this period',
                style: AppTypography.body(textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donut — top category % in center with subtle glow
// ─────────────────────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final double total;
  final List<MapEntry<String, double>> sorted;
  final String viewType;
  final bool isDark;

  const _DonutChart({
    required this.total,
    required this.sorted,
    required this.viewType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final fmt = NumberFormat('#,##0', 'en_IN');
    final topCat = sorted.isNotEmpty ? sorted.first : null;
    final topPct =
        topCat != null && total > 0 ? topCat.value / total * 100 : 0.0;
    final topColor =
        topCat != null ? AppColor.categoryColor(topCat.key) : AppColor.primary;

    final pieData = sorted
        .map((e) => _PieData(e.key, e.value, AppColor.categoryColor(e.key)))
        .toList();

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (topCat != null)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: topColor.withValues(alpha: isDark ? 0.18 : 0.10),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          SfCircularChart(
            margin: EdgeInsets.zero,
            series: <CircularSeries>[
              DoughnutSeries<_PieData, String>(
                dataSource: pieData,
                xValueMapper: (d, _) => d.category,
                yValueMapper: (d, _) => d.amount,
                pointColorMapper: (d, _) => d.color,
                innerRadius: '72%',
                radius: '86%',
                animationDuration: 450,
                enableTooltip: false,
              ),
            ],
          ),
          if (topCat != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topCat.key,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${topPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: topColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${fmt.format(total)}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
// Bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final bool isDark;
  final Color textPrimary;

  const _BarChart({
    required this.sorted,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final axisColor =
        isDark ? AppColor.textTertiary : AppColor.lightTextTertiary;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF3F2FA);
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    final data = sorted
        .map((e) => _BarCatData(
              label:
                  e.key.length > 11 ? '${e.key.substring(0, 10)}…' : e.key,
              amount: e.value,
              color: AppColor.categoryColor(e.key),
            ))
        .toList();

    return SizedBox(
      height: 210,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SfCartesianChart(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          plotAreaBorderWidth: 0,
          primaryXAxis: CategoryAxis(
            labelStyle: TextStyle(
                color: axisColor,
                fontSize: 10,
                fontWeight: FontWeight.w500),
            majorGridLines: const MajorGridLines(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            axisLine: const AxisLine(width: 0),
            labelIntersectAction: AxisLabelIntersectAction.rotate45,
          ),
          primaryYAxis: NumericAxis(
            isVisible: false,
            majorGridLines: MajorGridLines(
                width: 1,
                color: gridColor,
                dashArray: const [3, 3]),
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            color: isDark ? AppColor.darkElevated : Colors.white,
            borderColor: border,
            borderWidth: 1,
            textStyle: TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700),
            header: '',
          ),
          series: <CartesianSeries>[
            ColumnSeries<_BarCatData, String>(
              dataSource: data,
              xValueMapper: (d, _) => d.label,
              yValueMapper: (d, _) => d.amount,
              pointColorMapper: (d, _) => d.color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              animationDuration: 450,
              width: 0.5,
              enableTooltip: true,
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                labelAlignment: ChartDataLabelAlignment.top,
                builder: (data, point, series, pointIndex, seriesIndex) {
                  final val = (data as _BarCatData).amount;
                  final fmt = NumberFormat.compactCurrency(
                      symbol: '₹', decimalDigits: 0);
                  return Text(fmt.format(val),
                      style: TextStyle(
                          color: axisColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700));
                },
              ),
            ),
          ],
          onTooltipRender: (TooltipArgs args) {
            final idx = args.pointIndex?.toInt() ?? 0;
            if (args.dataPoints != null && args.dataPoints!.length > idx) {
              final val = args.dataPoints![idx].y as num;
              args.text = '₹${NumberFormat('#,##0').format(val)}';
            }
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category rows — full-width bars below each row
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryRows extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  final bool isDark;

  const _CategoryRows({
    required this.sorted,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final divider = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final pct = total > 0 ? cat.value / total : 0.0;
          final color = AppColor.categoryColor(cat.key);

          return Column(
            children: [
              if (i > 0) Divider(height: 1, thickness: 1, color: divider),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.key,
                            style: AppTypography.body(textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹${fmt.format(cat.value)}',
                          style: AppTypography.captionSemiBold(textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Full-width bar below the row
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: color.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transactions list — grouped by date with day total, category pill
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionsList extends StatelessWidget {
  final List<Map<String, dynamic>> monthTx;
  final bool isDark;

  const _TransactionsList({required this.monthTx, required this.isDark});

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> txs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final tx in txs) {
      final d = DateTime.parse(tx['date']);
      final day = DateTime(d.year, d.month, d.day);
      String label;
      if (day == today) {
        label = 'Today';
      } else if (day == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('EEEE, d MMM').format(d);
      }
      groups.putIfAbsent(label, () => []).add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final divider = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final groupLabelColor =
        isDark ? AppColor.textTertiary : AppColor.lightTextTertiary;

    final sorted = [...monthTx]..sort((a, b) =>
        DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    if (sorted.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 44,
                    color: AppColor.textTertiary.withValues(alpha: 0.25)),
                const SizedBox(height: 14),
                Text('No transactions this month',
                    style: AppTypography.body(textSecondary)),
                const SizedBox(height: 4),
                Text('🎉 Great savings!',
                    style: AppTypography.caption(textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    final grouped = _groupByDate(sorted);
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries.map((group) {
          final dateLabel = group.key;
          final txsInGroup = group.value;
          final dayTotal = txsInGroup
              .where((t) => t['type'] == 'expense')
              .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header with day spend total
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: groupLabelColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (dayTotal > 0)
                      Text(
                        '-₹${fmt.format(dayTotal)}',
                        style: TextStyle(
                          color: AppColor.expense.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color:
                                AppColor.primary.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: txsInGroup.asMap().entries.map((entry) {
                    final i = entry.key;
                    final tx = entry.value;
                    final isExpense = tx['type'] == 'expense';
                    final category = tx['category'] as String? ?? '';
                    final catColor = AppColor.categoryColor(category);
                    final amountColor =
                        isExpense ? AppColor.expense : AppColor.income;
                    final prefix = isExpense ? '-' : '+';
                    final amount = (tx['amount'] as num).toDouble();

                    return Column(
                      children: [
                        if (i > 0)
                          Divider(height: 1, thickness: 1, color: divider),
                        InkWell(
                          borderRadius: i == 0
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(20))
                              : i == txsInGroup.length - 1
                                  ? const BorderRadius.vertical(
                                      bottom: Radius.circular(20))
                                  : BorderRadius.zero,
                          splashColor:
                              AppColor.primary.withValues(alpha: 0.05),
                          onTap: () => Get.to(
                            () => TransactionDetailsScreen(
                              transaction: tx,
                              categoryList: categoryList,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color:
                                        catColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    controller.getCategoryIcon(
                                        category, categoryList),
                                    color: catColor,
                                    size: AppDimens.iconSM,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx['description']?.toString() ??
                                            '',
                                        style: AppTypography.body(
                                            textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: catColor
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                              color: catColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$prefix₹${fmt.format(amount)}',
                                  style: TextStyle(
                                    color: amountColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _PieData {
  final String category;
  final double amount;
  final Color color;
  _PieData(this.category, this.amount, this.color);
}

class _BarCatData {
  final String label;
  final double amount;
  final Color color;
  _BarCatData(
      {required this.label, required this.amount, required this.color});
}

class _MonthPoint {
  final String label;
  final double income;
  final double expense;
  _MonthPoint(
      {required this.label, required this.income, required this.expense});
}

// Keep for any external references
class PieData {
  final String category;
  final double amount;
  PieData(this.category, this.amount);
}