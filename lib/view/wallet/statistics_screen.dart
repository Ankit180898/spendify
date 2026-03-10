import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() {
    HapticFeedback.lightImpact();
    setState(() => _month = DateTime(_month.year, _month.month - 1));
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    HapticFeedback.lightImpact();
    setState(() => _month = DateTime(_month.year, _month.month + 1));
  }

  // ── Data helpers ──────────────────────────────────────────────────────────

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

  Map<String, double> _categoryTotals(List<Map<String, dynamic>> list) {
    final Map<String, double> out = {};
    for (final t in list) {
      if (t['type'] != 'expense') continue;
      final cat = t['category'] as String;
      out[cat] = (out[cat] ?? 0) + (t['amount'] as num).toDouble();
    }
    return out;
  }

  /// Last 6 months including current, in chronological order.
  List<DateTime> _last6Months() {
    return List.generate(6, (i) {
      final offset = 5 - i;
      return DateTime(_month.year, _month.month - offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
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
            final all = controller.transactions;
            final monthTx = _txForMonth(all, _month);
            final income = _sum(monthTx, 'income');
            final spent = _sum(monthTx, 'expense');
            final net = income - spent;
            final cats = _categoryTotals(monthTx);
            final sorted = cats.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // ── Month navigator ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: _MonthNav(
                    month: _month,
                    isDark: isDark,
                    onPrev: _prevMonth,
                    onNext: _nextMonth,
                    canGoNext: !(_month.year == DateTime.now().year &&
                        _month.month == DateTime.now().month),
                  ),
                ),

                // ── Hero numbers ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _HeroNumbers(
                    spent: spent,
                    income: income,
                    net: net,
                    isDark: isDark,
                  ),
                ),

                // ── Donut chart + category list ─────────────────────────
                if (sorted.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _DonutSection(
                      spent: spent,
                      sorted: sorted,
                      isDark: isDark,
                      context: context,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _CategoryList(
                      sorted: sorted,
                      total: spent,
                      isDark: isDark,
                    ),
                  ),
                ] else
                  SliverToBoxAdapter(
                    child: _EmptyMonth(isDark: isDark),
                  ),

                // ── 6-month bar trend ───────────────────────────────────
                SliverToBoxAdapter(
                  child: _TrendChart(
                    all: all,
                    months: _last6Months(),
                    isDark: isDark,
                    context: context,
                  ),
                ),

                // Spacer for nav bar
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        AppDimens.navBarHeight +
                        AppDimens.spaceLG,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Month navigator ───────────────────────────────────────────────────────────

class _MonthNav extends StatelessWidget {
  final DateTime month;
  final bool isDark;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const _MonthNav({
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
      padding: const EdgeInsets.fromLTRB(AppDimens.spaceLG, AppDimens.spaceLG,
          AppDimens.spaceLG, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Text('Analytics', style: AppTypography.heading2(textPrimary)),

          // Month nav pill
          Container(
            decoration: BoxDecoration(
              color: btnBg,
              borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppDimens.spaceSM),
                  child: Text(
                    DateFormat('MMM yyyy').format(month),
                    style: AppTypography.captionSemiBold(textSecondary),
                  ),
                ),
                _NavBtn(
                  icon: Icons.chevron_right,
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColor.primary : AppColor.textTertiary,
        ),
      ),
    );
  }
}

// ── Hero numbers ──────────────────────────────────────────────────────────────

class _HeroNumbers extends StatelessWidget {
  final double spent;
  final double income;
  final double net;
  final bool isDark;

  const _HeroNumbers({
    required this.spent,
    required this.income,
    required this.net,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final isPositive = net >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimens.spaceLG, AppDimens.spaceXXL,
          AppDimens.spaceLG, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total spent', style: AppTypography.caption(textSecondary)),
          const SizedBox(height: 4),
          Text(
            '₹${fmt.format(spent)}',
            style: AppTypography.amountDisplay(textPrimary),
          ),
          const SizedBox(height: AppDimens.spaceMD),
          Row(
            children: [
              _MiniStat(
                  label: 'Income',
                  value: '₹${fmt.format(income)}',
                  color: AppColor.income,
                  textSecondary: textSecondary),
              const SizedBox(width: AppDimens.spaceXXL),
              _MiniStat(
                  label: isPositive ? 'Saved' : 'Over budget',
                  value: '${isPositive ? '+' : '-'}₹${fmt.format(net.abs())}',
                  color: isPositive ? AppColor.income : AppColor.expense,
                  textSecondary: textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textSecondary;

  const _MiniStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption(textSecondary)),
        const SizedBox(width: 4),
        Text(value, style: AppTypography.captionSemiBold(color)),
      ],
    );
  }
}

// ── Donut chart ───────────────────────────────────────────────────────────────

class _DonutSection extends StatelessWidget {
  final double spent;
  final List<MapEntry<String, double>> sorted;
  final bool isDark;
  final BuildContext context;

  const _DonutSection({
    required this.spent,
    required this.sorted,
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final fmt = NumberFormat('#,##0', 'en_IN');

    final pieColors = sorted
        .map((e) => AppColor.categoryColor(e.key))
        .toList();

    final pieData = sorted
        .map((e) => _PieData(e.key, e.value, AppColor.categoryColor(e.key)))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimens.spaceLG, AppDimens.spaceXXL,
          AppDimens.spaceLG, 0),
      child: SizedBox(
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SfCircularChart(
              margin: EdgeInsets.zero,
              series: <CircularSeries>[
                DoughnutSeries<_PieData, String>(
                  dataSource: pieData,
                  xValueMapper: (d, _) => d.category,
                  yValueMapper: (d, _) => d.amount,
                  pointColorMapper: (d, _) => d.color,
                  innerRadius: '68%',
                  radius: '100%',
                  animationDuration: 800,
                  enableTooltip: false,
                ),
              ],
            ),
            // Center label
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('spent', style: AppTypography.label(textSecondary)),
                Text('₹${fmt.format(spent)}',
                    style: AppTypography.bodySemiBold(textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category flat list ────────────────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  final bool isDark;

  const _CategoryList({
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
      padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceLG, AppDimens.spaceLG, AppDimens.spaceLG, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.spaceMD),
            child: Text('By Category',
                style: AppTypography.captionSemiBold(textSecondary)),
          ),
          // Flat rows with dividers
          ...sorted.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final pct = total > 0 ? cat.value / total : 0.0;
            final color = AppColor.categoryColor(cat.key);

            return Column(
              children: [
                if (i > 0) Divider(height: 1, thickness: 1, color: divider),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      // Color dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      // Name
                      Expanded(
                        flex: 3,
                        child: Text(
                          cat.key,
                          style: AppTypography.body(textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Bar
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: color.withOpacity(0.1),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                      ),
                      // Amount
                      Text(
                        '₹${fmt.format(cat.value)}',
                        style: AppTypography.captionSemiBold(textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyMonth extends StatelessWidget {
  final bool isDark;
  const _EmptyMonth({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 48, color: textSecondary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No transactions this month',
                style: AppTypography.body(textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── 6-month bar trend ─────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> all;
  final List<DateTime> months;
  final bool isDark;
  final BuildContext context;

  const _TrendChart({
    required this.all,
    required this.months,
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final bg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final axisColor = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final gridColor =
        isDark ? Colors.white.withOpacity(0.06) : AppColor.lightBorder;

    // Build chart data
    final data = months.map((m) {
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59);
      final txs = all.where((t) {
        final d = DateTime.parse(t['date']);
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
      return _BarData(
        label: DateFormat('MMM').format(m),
        income: txs
            .where((t) => t['type'] == 'income')
            .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble()),
        expense: txs
            .where((t) => t['type'] == 'expense')
            .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble()),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimens.spaceLG, AppDimens.spaceXXL,
          AppDimens.spaceLG, 0),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spaceLG),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('6-Month Trend',
                    style: AppTypography.bodySemiBold(textPrimary)),
                Row(
                  children: [
                    _Dot(color: AppColor.income, label: 'In'),
                    const SizedBox(width: AppDimens.spaceMD),
                    _Dot(color: AppColor.expense, label: 'Out'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spaceLG),
            SizedBox(
              height: 180,
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                plotAreaBorderWidth: 0,
                primaryXAxis: CategoryAxis(
                  labelStyle: TextStyle(color: axisColor, fontSize: 11),
                  majorGridLines: const MajorGridLines(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  axisLine: const AxisLine(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: TextStyle(color: axisColor, fontSize: 11),
                  majorGridLines: MajorGridLines(
                      width: 1,
                      color: gridColor,
                      dashArray: const [4, 4]),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  numberFormat: NumberFormat.compact(),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  color: isDark ? AppColor.darkElevated : AppColor.lightSurface,
                  borderColor: border,
                  textStyle: TextStyle(color: textPrimary, fontSize: 12),
                ),
                series: <CartesianSeries>[
                  SplineAreaSeries<_BarData, String>(
                    name: 'Income',
                    dataSource: data,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.income,
                    splineType: SplineType.monotonic,
                    color: AppColor.income.withOpacity(0.12),
                    borderColor: AppColor.income,
                    borderWidth: 2.0,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColor.income.withOpacity(0.25),
                        AppColor.income.withOpacity(0.0),
                      ],
                    ),
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      height: 6,
                      width: 6,
                      shape: DataMarkerType.circle,
                      borderWidth: 2,
                      borderColor: AppColor.income,
                      color: isDark ? AppColor.darkCard : AppColor.lightSurface,
                    ),
                    enableTooltip: true,
                  ),
                  SplineAreaSeries<_BarData, String>(
                    name: 'Expense',
                    dataSource: data,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.expense,
                    splineType: SplineType.monotonic,
                    color: AppColor.expense.withOpacity(0.12),
                    borderColor: AppColor.expense,
                    borderWidth: 2.0,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColor.expense.withOpacity(0.25),
                        AppColor.expense.withOpacity(0.0),
                      ],
                    ),
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      height: 6,
                      width: 6,
                      shape: DataMarkerType.circle,
                      borderWidth: 2,
                      borderColor: AppColor.expense,
                      color: isDark ? AppColor.darkCard : AppColor.lightSurface,
                    ),
                    enableTooltip: true,
                  ),
                ],
                onTooltipRender: (TooltipArgs args) {
                  if (args.dataPoints != null && args.dataPoints!.isNotEmpty) {
                    args.text =
                        '₹${NumberFormat('#,##0').format(args.dataPoints![0].y)}';
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ts = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.label(ts)),
      ],
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _PieData {
  final String category;
  final double amount;
  final Color color;
  _PieData(this.category, this.amount, this.color);
}

class _BarData {
  final String label;
  final double income;
  final double expense;
  _BarData({required this.label, required this.income, required this.expense});
}

// Keep for any external references
class PieData {
  final String category;
  final double amount;
  PieData(this.category, this.amount);
}
