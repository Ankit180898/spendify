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

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _month;
  bool _showBar = false;
  String _viewType = 'expense';

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

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
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

                SliverToBoxAdapter(
                  child: _HeroNumbers(
                    spent: spent,
                    income: income,
                    net: net,
                    isDark: isDark,
                  ),
                ),

                // Chart card (controls + chart + category list in one block)
                SliverToBoxAdapter(
                  child: _ChartCard(
                    sorted: sorted,
                    total: total,
                    viewType: _viewType,
                    showBar: _showBar,
                    isDark: isDark,
                    onViewTypeChanged: (v) => setState(() => _viewType = v),
                    onChartTypeChanged: (b) => setState(() => _showBar = b),
                  ),
                ),

                SliverToBoxAdapter(
                  child: _MonthTransactionsList(
                    monthTx: monthTx,
                    isDark: isDark,
                  ),
                ),

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
      padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceLG, AppDimens.spaceLG, AppDimens.spaceLG, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Analytics', style: AppTypography.heading2(textPrimary)),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spaceSM),
                  child: Text(
                    DateFormat('MMM yyyy').format(month),
                    style: AppTypography.captionSemiBold(textSecondary),
                  ),
                ),
                _NavBtn(
                    icon: Icons.chevron_right,
                    onTap: canGoNext ? onNext : null),
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
        child: Icon(icon,
            size: 18,
            color:
                onTap != null ? AppColor.primary : AppColor.textTertiary),
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
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final divider = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final isPositive = net >= 0;
    final netColor = isPositive ? AppColor.income : AppColor.expense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceLG, AppDimens.spaceXXL, AppDimens.spaceLG, 0),
      child: Row(
        children: [
          // Income
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Income',
                    style: AppTypography.caption(textSecondary)),
                const SizedBox(height: 4),
                Text('₹${fmt.format(income)}',
                    style: AppTypography.bodySemiBold(AppColor.income)),
              ],
            ),
          ),
          // Divider
          Container(width: 1, height: 36, color: divider),
          // Expenses
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(left: AppDimens.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expenses',
                      style: AppTypography.caption(textSecondary)),
                  const SizedBox(height: 4),
                  Text('₹${fmt.format(spent)}',
                      style:
                          AppTypography.bodySemiBold(AppColor.expense)),
                ],
              ),
            ),
          ),
          // Divider
          Container(width: 1, height: 36, color: divider),
          // Net
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(left: AppDimens.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isPositive ? 'Saved' : 'Over',
                      style: AppTypography.caption(textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${isPositive ? '+' : '-'}₹${fmt.format(net.abs())}',
                    style: AppTypography.bodySemiBold(netColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Combined chart card ───────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  final String viewType;
  final bool showBar;
  final bool isDark;
  final ValueChanged<String> onViewTypeChanged;
  final ValueChanged<bool> onChartTypeChanged;

  const _ChartCard({
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
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final btnBg = isDark ? AppColor.darkElevated : AppColor.lightBg;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceLG, AppDimens.spaceXXL, AppDimens.spaceLG, 0),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
          border: Border.all(color: border),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColor.primary.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: title + toggles ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.spaceLG,
                  AppDimens.spaceLG, AppDimens.spaceLG, 0),
              child: Row(
                children: [
                  Text('Breakdown',
                      style: AppTypography.bodySemiBold(textPrimary)),
                  const Spacer(),
                  // Income / Expense pill toggle
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: btnBg,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusCircle),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypePill(
                          label: 'Exp',
                          selected: viewType == 'expense',
                          color: AppColor.expense,
                          isDark: isDark,
                          onTap: () => onViewTypeChanged('expense'),
                        ),
                        _TypePill(
                          label: 'Inc',
                          selected: viewType == 'income',
                          color: AppColor.income,
                          isDark: isDark,
                          onTap: () => onViewTypeChanged('income'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.spaceSM),
                  // Chart type icon toggle
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: btnBg,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusCircle),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ChartTypeBtn(
                          icon: Icons.pie_chart_outline_rounded,
                          selected: !showBar,
                          onTap: () => onChartTypeChanged(false),
                        ),
                        _ChartTypeBtn(
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

            // ── Chart ───────────────────────────────────────────────
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text('No data for this period',
                      style: AppTypography.body(textSecondary)),
                ),
              )
            else ...[
              showBar
                  ? _BarChart(
                      sorted: sorted, isDark: isDark, textPrimary: textPrimary)
                  : _DonutChart(
                      total: total,
                      sorted: sorted,
                      viewType: viewType,
                      isDark: isDark),

              // ── Divider ─────────────────────────────────────────
              Divider(
                  height: 1,
                  thickness: 1,
                  color: border,
                  indent: AppDimens.spaceLG,
                  endIndent: AppDimens.spaceLG),

              // ── Category rows ────────────────────────────────────
              _CategoryRows(
                  sorted: sorted, total: total, isDark: isDark),
            ],

            const SizedBox(height: AppDimens.spaceMD),
          ],
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _TypePill({
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
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: selected
              ? AppTypography.captionSemiBold(color)
              : AppTypography.label(textSecondary),
        ),
      ),
    );
  }
}

class _ChartTypeBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChartTypeBtn({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColor.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
        ),
        alignment: Alignment.center,
        child: Icon(icon,
            size: 16,
            color: selected ? AppColor.primary : AppColor.textTertiary),
      ),
    );
  }
}

// ── Donut chart ───────────────────────────────────────────────────────────────

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
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final fmt = NumberFormat('#,##0', 'en_IN');

    final pieData = sorted
        .map((e) => _PieData(e.key, e.value, AppColor.categoryColor(e.key)))
        .toList();

    return SizedBox(
      height: 200,
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
                radius: '90%',
                animationDuration: 0,
                enableTooltip: false,
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(viewType, style: AppTypography.label(textSecondary)),
              const SizedBox(height: 2),
              Text('₹${fmt.format(total)}',
                  style: AppTypography.bodySemiBold(textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Column (bar) chart ────────────────────────────────────────────────────────

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
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF0EEF8);
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    final data = sorted
        .map((e) => _BarCatData(
              label: e.key.length > 8 ? '${e.key.substring(0, 7)}…' : e.key,
              amount: e.value,
              color: AppColor.categoryColor(e.key),
            ))
        .toList();

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(top: AppDimens.spaceLG),
        child: SfCartesianChart(
          margin: const EdgeInsets.symmetric(horizontal: AppDimens.spaceMD),
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
                dashArray: const [4, 4]),
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            color: isDark ? AppColor.darkElevated : Colors.white,
            borderColor: border,
            borderWidth: 1,
            textStyle: TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
            header: '',
          ),
          series: <CartesianSeries>[
            ColumnSeries<_BarCatData, String>(
              dataSource: data,
              xValueMapper: (d, _) => d.label,
              yValueMapper: (d, _) => d.amount,
              pointColorMapper: (d, _) => d.color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
              animationDuration: 0,
              width: 0.55,
              enableTooltip: true,
            ),
          ],
          onTooltipRender: (TooltipArgs args) {
            if (args.dataPoints != null && args.dataPoints!.isNotEmpty) {
              final val = args.dataPoints![0].y as num;
              args.text = '₹${NumberFormat('#,##0').format(val)}';
            }
          },
        ),
      ),
    );
  }
}

// ── Category rows ─────────────────────────────────────────────────────────────

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
    final divider = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceLG, AppDimens.spaceMD, AppDimens.spaceLG, 0),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final pct = total > 0 ? cat.value / total : 0.0;
          final color = AppColor.categoryColor(cat.key);

          return Column(
            children: [
              if (i > 0)
                Divider(height: 1, thickness: 1, color: divider),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Text(
                        cat.key,
                        style: AppTypography.body(textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 3,
                            backgroundColor:
                                color.withValues(alpha: 0.1),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '₹${fmt.format(cat.value)}',
                      style:
                          AppTypography.captionSemiBold(textPrimary),
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

// ── Monthly transactions list ─────────────────────────────────────────────────

class _MonthTransactionsList extends StatelessWidget {
  final List<Map<String, dynamic>> monthTx;
  final bool isDark;

  const _MonthTransactionsList({
    required this.monthTx,
    required this.isDark,
  });

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

    final sorted = [...monthTx]
      ..sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceLG, AppDimens.spaceXXL, AppDimens.spaceLG, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transactions',
                  style: AppTypography.bodySemiBold(textPrimary)),
              if (sorted.isNotEmpty)
                Text('${sorted.length}',
                    style: AppTypography.captionSemiBold(textSecondary)),
            ],
          ),
          const SizedBox(height: AppDimens.spaceMD),
          if (sorted.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppDimens.spaceXXL),
              child: Center(
                child: Text('No transactions this month',
                    style: AppTypography.body(textSecondary)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                border: Border.all(color: border),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color:
                              AppColor.primary.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: sorted.asMap().entries.map((entry) {
                  final i = entry.key;
                  final tx = entry.value;
                  final isExpense = tx['type'] == 'expense';
                  final category = tx['category'] as String? ?? '';
                  final catColor = AppColor.categoryColor(category);
                  final amountColor =
                      isExpense ? AppColor.expense : AppColor.income;
                  final prefix = isExpense ? '-' : '+';
                  final fmt = NumberFormat('#,##0', 'en_IN');
                  final amount = (tx['amount'] as num).toDouble();
                  final date = DateFormat('d MMM')
                      .format(DateTime.parse(tx['date']));

                  return Column(
                    children: [
                      if (i > 0)
                        Divider(
                            height: 1,
                            thickness: 1,
                            color: divider),
                      InkWell(
                        borderRadius: i == 0
                            ? const BorderRadius.vertical(
                                top: Radius.circular(AppDimens.radiusXL))
                            : i == sorted.length - 1
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(
                                        AppDimens.radiusXL))
                                : BorderRadius.zero,
                        splashColor:
                            AppColor.primary.withValues(alpha: 0.06),
                        onTap: () => Get.to(
                          () => TransactionDetailsScreen(
                            transaction: tx,
                            categoryList: categoryList,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.spaceLG,
                              vertical: AppDimens.spaceMD),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
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
                              const SizedBox(width: AppDimens.spaceMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['description']?.toString() ??
                                          '',
                                      style:
                                          AppTypography.body(textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$category · $date',
                                      style: AppTypography.caption(
                                          textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppDimens.spaceSM),
                              Text(
                                '$prefix₹${fmt.format(amount)}',
                                style: AppTypography.captionSemiBold(
                                    amountColor),
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
        ],
      ),
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

class _BarCatData {
  final String label;
  final double amount;
  final Color color;
  _BarCatData(
      {required this.label, required this.amount, required this.color});
}

// Keep for any external references
class PieData {
  final String category;
  final double amount;
  PieData(this.category, this.amount);
}
