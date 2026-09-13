import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/all_transaction_screen.dart';
import 'package:spendify/view/wallet/transaction_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

PhosphorIconData _categoryIcon(String category, bool isIncome) {
  final match = categoryList.firstWhere(
    (c) => c.name == category,
    orElse: () => CategoriesModel(
      name: category,
      icon: isIncome ? PhosphorIconsLight.arrowCircleDown : PhosphorIconsLight.tag,
    ),
  );
  return match.icon as PhosphorIconData;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _month;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    int pickerYear = _month.year;
    final allTx = Get.find<HomeController>().allTransactions;
    final activeMonths = <String>{};
    for (final t in allTx) {
      final d = DateTime.tryParse(t['date'] ?? '');
      if (d != null) activeMonths.add('${d.year}-${d.month}');
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => setLocal(() => pickerYear--),
                        icon: const PhosphorIcon(PhosphorIconsLight.caretLeft, color: AppColor.primary, size: 16),
                      ),
                      Text('$pickerYear',
                          style: GoogleFonts.urbanist(color: AppColor.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(
                        onPressed: pickerYear >= now.year ? null : () => setLocal(() => pickerYear++),
                        icon: PhosphorIcon(PhosphorIconsLight.caretRight,
                            color: pickerYear >= now.year ? AppColor.textTertiary : AppColor.primary, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3, shrinkWrap: true,
                    childAspectRatio: 2.0, mainAxisSpacing: 8, crossAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(12, (i) {
                      final isFuture = pickerYear == now.year && (i + 1) > now.month;
                      final isSelected = pickerYear == _month.year && (i + 1) == _month.month;
                      final hasData = activeMonths.contains('$pickerYear-${i + 1}');
                      return GestureDetector(
                        onTap: isFuture ? null : () {
                          setState(() => _month = DateTime(pickerYear, i + 1));
                          Navigator.of(ctx).pop();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColor.primary : const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(months[i],
                                  style: GoogleFonts.urbanist(
                                    color: isFuture ? AppColor.textTertiary : (isSelected ? Colors.white : AppColor.textPrimary),
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  )),
                              const SizedBox(height: 3),
                              Container(
                                width: 4, height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasData && !isFuture
                                      ? (isSelected ? Colors.white.withValues(alpha: 0.7) : AppColor.primary)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  List<Map<String, dynamic>> _txForMonth(List<Map<String, dynamic>> all, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end   = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return all.where((t) {
      final d = t['parsedDate'] as DateTime? ?? DateTime.tryParse(t['date'] ?? '');
      if (d == null) return false;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  double _sum(List<Map<String, dynamic>> list, String type) =>
      list.where((t) => t['type'] == type).fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

  Map<String, double> _categoryTotals(List<Map<String, dynamic>> list, String type) {
    final Map<String, double> out = {};
    for (final t in list) {
      if (t['type'] != type) continue;
      final cat = t['category'];
      if (cat == null || (cat as String).isEmpty) continue;
      out[cat] = (out[cat] ?? 0) + (t['amount'] as num).toDouble();
    }
    return out;
  }

  // Previous month total for comparison
  double _prevMonthSum(List<Map<String, dynamic>> all, String type) {
    final prev = DateTime(_month.year, _month.month - 1);
    return _sum(_txForMonth(all, prev), type);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            final ctrl    = Get.find<HomeController>();
            final all     = ctrl.allTransactions;
            final monthTx = _txForMonth(all, _month);

            final income = _sum(monthTx, 'income');
            final spent  = _sum(monthTx, 'expense');
            final net    = income - spent;

            final viewType    = _tab.index == 0 ? 'expense' : 'income';
            final activeTotal = viewType == 'expense' ? spent : income;
            final activeColor = viewType == 'expense' ? AppColor.expense : AppColor.income;

            final prevTotal = _prevMonthSum(all, viewType);
            final diff      = activeTotal - prevTotal;

            final cats   = _categoryTotals(monthTx, viewType);
            final sorted = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

            final filteredTx = monthTx.where((t) => t['type'] == viewType).toList()
              ..sort((a, b) {
                final da = a['parsedDate'] as DateTime? ?? DateTime.tryParse(a['date'] ?? '') ?? DateTime(0);
                final db = b['parsedDate'] as DateTime? ?? DateTime.tryParse(b['date'] ?? '') ?? DateTime(0);
                return db.compareTo(da);
              });

            final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
            final dayMap = <int, double>{};
            for (final tx in monthTx) {
              if (tx['type'] != viewType) continue;
              final d = (tx['parsedDate'] as DateTime? ?? DateTime.tryParse(tx['date'] ?? ''))?.day;
              if (d == null) continue;
              dayMap[d] = (dayMap[d] ?? 0) + (tx['amount'] as num).toDouble();
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroSection(
                    month: _month,
                    tab: _tab,
                    onPrev: _prevMonth,
                    onNext: _nextMonth,
                    onMonthPick: _pickMonth,
                    canGoNext: !(_month.year == DateTime.now().year && _month.month == DateTime.now().month),
                    spent: spent,
                    income: income,
                    net: net,
                    activeTotal: activeTotal,
                    activeColor: activeColor,
                    viewType: viewType,
                    daysInMonth: daysInMonth,
                    dayMap: dayMap,
                    diff: diff,
                    prevTotal: prevTotal,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategorySection(
                    sorted: sorted,
                    total: activeTotal,
                    viewType: viewType,
                    month: _month,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _TransactionSection(
                    filteredTx: filteredTx,
                    viewType: viewType,
                    month: _month,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + AppDimens.navBarHeight + AppDimens.spaceLG,
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero — month nav + tabs + big number + area chart + overview stats
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatefulWidget {
  final DateTime month;
  final TabController tab;
  final VoidCallback onPrev, onNext, onMonthPick;
  final bool canGoNext;
  final double spent, income, net, activeTotal, prevTotal, diff;
  final Color activeColor;
  final String viewType;
  final int daysInMonth;
  final Map<int, double> dayMap;

  const _HeroSection({
    required this.month,
    required this.tab,
    required this.onPrev,
    required this.onNext,
    required this.onMonthPick,
    required this.canGoNext,
    required this.spent,
    required this.income,
    required this.net,
    required this.activeTotal,
    required this.activeColor,
    required this.viewType,
    required this.daysInMonth,
    required this.dayMap,
    required this.diff,
    required this.prevTotal,
  });

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  int? _selectedDay;

  @override
  void didUpdateWidget(_HeroSection old) {
    super.didUpdateWidget(old);
    if (old.viewType != widget.viewType || old.month != widget.month) {
      _selectedDay = null;
    }
  }

  // Build cumulative spending list (for area chart)
  List<double> _cumulativePoints() {
    double cum = 0;
    return List.generate(widget.daysInMonth, (i) {
      cum += widget.dayMap[i + 1] ?? 0;
      return cum;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt        = NumberFormat('#,##0', 'en_IN');
    final sym        = Get.find<HomeController>().currencySymbol.value;
    final isExpense  = widget.viewType == 'expense';
    final isPositive = widget.net >= 0;
    final now        = DateTime.now();
    final cumPoints  = _cumulativePoints();
    final maxCum     = cumPoints.isNotEmpty ? cumPoints.reduce(math.max) : 1.0;
    final hasData    = maxCum > 0;

    // Tooltip for selected day
    String? tooltipText;
    if (_selectedDay != null) {
      final dayVal = widget.dayMap[_selectedDay!] ?? 0;
      final selDate = DateTime(widget.month.year, widget.month.month, _selectedDay!);
      tooltipText = '${DateFormat('d MMM').format(selDate)}  ·  $sym${fmt.format(dayVal)}';
    }

    // vs last month pill
    final hasPrev = widget.prevTotal > 0;
    final pctDiff = hasPrev ? (widget.diff / widget.prevTotal * 100) : 0.0;
    final isUp    = widget.diff >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Month nav ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onPrev,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(right: 12, top: 4, bottom: 4),
                  child: PhosphorIcon(PhosphorIconsLight.caretLeft, size: 15, color: AppColor.primary),
                ),
              ),
              GestureDetector(
                onTap: widget.onMonthPick,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(widget.month),
                      style: GoogleFonts.urbanist(
                          color: AppColor.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    const PhosphorIcon(PhosphorIconsLight.caretUpDown, size: 12, color: AppColor.primary),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.canGoNext ? widget.onNext : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                  child: PhosphorIcon(PhosphorIconsLight.caretRight,
                      size: 15,
                      color: widget.canGoNext ? AppColor.primary : AppColor.textTertiary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Tab — two underlined text buttons ─────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _TabButton(
                label: 'Expenses',
                active: widget.tab.index == 0,
                activeColor: AppColor.expense,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.tab.animateTo(0);
                },
              ),
              const SizedBox(width: 24),
              _TabButton(
                label: 'Income',
                active: widget.tab.index == 1,
                activeColor: AppColor.income,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.tab.animateTo(1);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Big amount + comparison pill ──────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              key: ValueKey(widget.viewType),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sym${fmt.format(widget.activeTotal)}',
                    style: GoogleFonts.urbanist(
                      color: AppColor.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.0,
                      height: 1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${isExpense ? 'spent' : 'earned'} in ${DateFormat('MMMM').format(widget.month)}',
                        style: GoogleFonts.urbanist(color: AppColor.textSecondary, fontSize: 13),
                      ),
                      if (hasPrev) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isUp
                                ? (isExpense ? AppColor.expense : AppColor.income).withValues(alpha: 0.1)
                                : AppColor.income.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PhosphorIcon(
                                isUp ? PhosphorIconsLight.trendUp : PhosphorIconsLight.trendDown,
                                size: 11,
                                color: isUp
                                    ? (isExpense ? AppColor.expense : AppColor.income)
                                    : AppColor.income,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${pctDiff.abs().toStringAsFixed(0)}%',
                                style: GoogleFonts.urbanist(
                                  color: isUp
                                      ? (isExpense ? AppColor.expense : AppColor.income)
                                      : AppColor.income,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Area chart ────────────────────────────────────────
        if (hasData) ...[
          SizedBox(
            height: 160,
            child: _AreaChartWidget(
              cumPoints: cumPoints,
              maxCum: maxCum,
              dayMap: widget.dayMap,
              daysInMonth: widget.daysInMonth,
              color: AppColor.textPrimary,
              currentMonth: widget.month,
              todayDay: (widget.month.year == now.year && widget.month.month == now.month)
                  ? now.day : null,
              selectedDay: _selectedDay,
              onDaySelected: (d) => setState(() => _selectedDay = d),
            ),
          ),
          // X-axis labels — flex weights match day intervals so labels
          // align with the corresponding points on the curve above.
          Row(
            children: [
              Text('1',
                  style: GoogleFonts.urbanist(
                      color: AppColor.textTertiary, fontSize: 10)),
              const Spacer(flex: 6),
              Text('7',
                  style: GoogleFonts.urbanist(
                      color: AppColor.textTertiary, fontSize: 10)),
              const Spacer(flex: 7),
              Text('14',
                  style: GoogleFonts.urbanist(
                      color: AppColor.textTertiary, fontSize: 10)),
              const Spacer(flex: 7),
              Text('21',
                  style: GoogleFonts.urbanist(
                      color: AppColor.textTertiary, fontSize: 10)),
              Spacer(flex: widget.daysInMonth - 21),
              Text('${widget.daysInMonth}',
                  style: GoogleFonts.urbanist(
                      color: AppColor.textTertiary, fontSize: 10)),
            ],
          ),
          // Tooltip
          if (tooltipText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                tooltipText,
                style: GoogleFonts.urbanist(color: AppColor.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 24),
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F5FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No ${isExpense ? 'expenses' : 'income'} this month',
                  style: GoogleFonts.urbanist(color: AppColor.textTertiary, fontSize: 13),
                ),
              ),
            ),
          ),
        ],

        // ── Overview stats ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OVERVIEW',
                  style: GoogleFonts.urbanist(
                    color: AppColor.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  )),
              const SizedBox(height: 12),
              _StatRow(
                label: isExpense ? 'Income this month' : 'Expenses this month',
                value: '$sym${fmt.format(isExpense ? widget.income : widget.spent)}',
                valueColor: isExpense ? AppColor.income : AppColor.expense,
              ),
              _StatRow(
                label: isPositive ? 'Saved' : 'Over budget',
                value: '${isPositive ? '+' : '-'}$sym${fmt.format(widget.net.abs())}',
                valueColor: isPositive ? AppColor.income : AppColor.expense,
              ),
              if (widget.income > 0 && widget.spent > 0)
                _StatRow(
                  label: 'Spend rate',
                  value: '${(widget.spent / widget.income * 100).toStringAsFixed(0)}% of income',
                  valueColor: AppColor.textPrimary,
                  last: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 0.5, color: AppColor.border),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab button — underline style
// ─────────────────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.active, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.urbanist(
              color: active ? AppColor.textPrimary : AppColor.textTertiary,
              fontSize: 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: active ? 32.0 : 0.0,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smooth bezier area chart — cumulative spending curve (Finsight-style)
// ─────────────────────────────────────────────────────────────────────────────

class _AreaChartWidget extends StatelessWidget {
  final List<double> cumPoints;
  final double maxCum;
  final Map<int, double> dayMap;
  final int daysInMonth;
  final Color color;
  final DateTime currentMonth;
  final int? todayDay;
  final int? selectedDay;
  final ValueChanged<int?> onDaySelected;

  const _AreaChartWidget({
    required this.cumPoints,
    required this.maxCum,
    required this.dayMap,
    required this.daysInMonth,
    required this.color,
    required this.currentMonth,
    required this.todayDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  int _dayFromX(double dx, double width) {
    final ratio = (dx / width).clamp(0.0, 1.0);
    return (ratio * (daysInMonth - 1)).round() + 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final width = constraints.maxWidth;
      return GestureDetector(
        onTapDown: (d) => onDaySelected(_dayFromX(d.localPosition.dx, width)),
        onPanUpdate: (d) => onDaySelected(_dayFromX(d.localPosition.dx, width)),
        onTapUp: (_) => onDaySelected(null),
        onPanEnd: (_) => onDaySelected(null),
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          size: Size(width, constraints.maxHeight),
          painter: _AreaPainter(
            cumPoints: cumPoints,
            maxCum: maxCum,
            color: color,
            todayDayIndex: todayDay != null ? todayDay! - 1 : null,
            selectedDayIndex: selectedDay != null ? selectedDay! - 1 : null,
          ),
        ),
      );
    });
  }
}

class _AreaPainter extends CustomPainter {
  final List<double> cumPoints;
  final double maxCum;
  final Color color;
  final int? todayDayIndex;
  final int? selectedDayIndex;

  const _AreaPainter({
    required this.cumPoints,
    required this.maxCum,
    required this.color,
    required this.todayDayIndex,
    required this.selectedDayIndex,
  });

  List<Offset> _pixelPoints(Size size) {
    final n = cumPoints.length;
    if (n == 0) return [];
    const padV = 16.0;
    return List.generate(n, (i) {
      final x = i / (n - 1) * size.width;
      final y = padV + (1 - (maxCum > 0 ? cumPoints[i] / maxCum : 0)) * (size.height - padV * 2);
      return Offset(x, y);
    });
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i < pts.length - 2 ? pts[i + 2] : p2;
      final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pts = _pixelPoints(size);
    if (pts.isEmpty) return;

    final linePath = _smoothPath(pts);

    // Line — flat, monochrome stroke. No fill: a filled area reads as
    // "decoration"; a bare line reads as "data".
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Selected / today indicator — a faint dashed guide only, no marker dot.
    final showIdx = selectedDayIndex ?? todayDayIndex;
    if (showIdx != null && showIdx >= 0 && showIdx < pts.length) {
      final pt = pts[showIdx];
      final dashPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..strokeWidth = 1.0;
      double dy = 0;
      while (dy < size.height) {
        canvas.drawLine(Offset(pt.dx, dy), Offset(pt.dx, math.min(dy + 4, size.height)), dashPaint);
        dy += 8;
      }
    }
  }

  @override
  bool shouldRepaint(_AreaPainter old) =>
      old.cumPoints != cumPoints ||
      old.color != color ||
      old.selectedDayIndex != selectedDayIndex ||
      old.todayDayIndex != todayDayIndex;
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview stat row (below chart)
// ─────────────────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool last;

  const _StatRow({required this.label, required this.value, required this.valueColor, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Text(label,
                  style: GoogleFonts.urbanist(color: AppColor.textSecondary, fontSize: 13)),
              const Spacer(),
              Text(value,
                  style: GoogleFonts.urbanist(
                    color: valueColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, thickness: 0.5, color: AppColor.border),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category section — flat list, Finsight "Your Investment" style
// ─────────────────────────────────────────────────────────────────────────────

List<Color> _tabPalette(String viewType, int count) {
  final isExpense = viewType == 'expense';
  final palette = isExpense
      ? const [
          Color(0xFFFF5370), Color(0xFFFF7A5C), Color(0xFFFF9A6C),
          Color(0xFFFFB88A), Color(0xFFFFD0A8), Color(0xFFFFE8CC),
        ]
      : const [
          Color(0xFF00C896), Color(0xFF26D4A4), Color(0xFF4DDEB4),
          Color(0xFF80E8C8), Color(0xFFAAF0DA), Color(0xFFCCF7EC),
        ];
  return List.generate(count, (i) => palette[i.clamp(0, palette.length - 1)]);
}

class _CategorySection extends StatefulWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  final String viewType;
  final DateTime month;

  const _CategorySection({
    required this.sorted,
    required this.total,
    required this.viewType,
    required this.month,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _showAll = false;

  @override
  void didUpdateWidget(_CategorySection old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month || old.viewType != widget.viewType) _showAll = false;
  }

  @override
  Widget build(BuildContext context) {
    final sorted    = widget.sorted;
    final total     = widget.total;
    final viewType  = widget.viewType;
    final sym       = Get.find<HomeController>().currencySymbol.value;
    final fmt       = NumberFormat('#,##0', 'en_IN');
    final isExpense = viewType == 'expense';
    final visible   = _showAll ? sorted : sorted.take(5).toList();
    final colors    = _tabPalette(viewType, visible.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CATEGORIES',
              style: GoogleFonts.urbanist(
                color: AppColor.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 14),

          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppColor.textTertiary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          isExpense ? PhosphorIconsLight.chartPie : PhosphorIconsLight.trendUp,
                          color: AppColor.textTertiary.withValues(alpha: 0.35),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('No ${isExpense ? 'expense' : 'income'} categories this month',
                        style: GoogleFonts.urbanist(color: AppColor.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
          else ...[
            ...visible.asMap().entries.map((entry) {
              final i     = entry.key;
              final cat   = entry.value;
              final pct   = total > 0 ? cat.value / total : 0.0;
              final color = colors[i];

              return GestureDetector(
                onTap: () => Get.to(
                  () => AllTransactionsScreen(
                    initialType: viewType,
                    initialMonth: widget.month,
                    initialCategory: cat.key,
                  ),
                  transition: Transition.cupertino,
                ),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          // Colored dot indicator
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),

                          // Category name + thin bar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.key,
                                    style: GoogleFonts.urbanist(
                                      color: AppColor.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 5),
                                // Full-width colored bar
                                Stack(
                                  children: [
                                    Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: pct.clamp(0.0, 1.0),
                                      child: Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Amount + percentage
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$sym${fmt.format(cat.value)}',
                                style: GoogleFonts.urbanist(
                                  color: AppColor.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text('${(pct * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.urbanist(color: AppColor.textTertiary, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (i < visible.length - 1)
                      const Divider(height: 1, thickness: 0.5, color: AppColor.border, indent: 22),
                  ],
                ),
              );
            }),

            if (!_showAll && sorted.length > 5)
              GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _showAll = true); },
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text('+ ${sorted.length - 5} more categories',
                      style: GoogleFonts.urbanist(color: AppColor.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            if (_showAll && sorted.length > 5)
              GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _showAll = false); },
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text('Show less',
                      style: GoogleFonts.urbanist(color: AppColor.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 0.5, color: AppColor.border),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction section — flat list, Finsight "Your Investment" row style
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionSection extends StatelessWidget {
  final List<Map<String, dynamic>> filteredTx;
  final String viewType;
  final DateTime month;

  const _TransactionSection({
    required this.filteredTx,
    required this.viewType,
    required this.month,
  });

  String _title(Map<String, dynamic> tx) {
    final t = tx['description'];
    if (t != null && (t as String).isNotEmpty) return t;
    final cat = (tx['category'] as String?) ?? '';
    if (cat.isNotEmpty) return cat;
    return tx['type'] == 'income' ? 'Income' : 'Expense';
  }

  @override
  Widget build(BuildContext context) {
    final sym       = Get.find<HomeController>().currencySymbol.value;
    final isExpense = viewType == 'expense';
    final amtColor  = isExpense ? AppColor.expense : AppColor.income;
    final fmt       = NumberFormat('#,##0', 'en_IN');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isExpense ? 'TRANSACTIONS' : 'INCOME',
              style: GoogleFonts.urbanist(
                color: AppColor.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 14),

          if (filteredTx.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppColor.textTertiary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: PhosphorIcon(PhosphorIconsLight.receipt,
                            color: AppColor.textTertiary.withValues(alpha: 0.35), size: 22),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('No ${isExpense ? 'expenses' : 'income'} this month',
                        style: GoogleFonts.urbanist(color: AppColor.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
          else ...[
            ...filteredTx.take(5).toList().asMap().entries.map((e) {
              final idx          = e.key;
              final tx           = e.value;
              final cat          = (tx['category'] as String?) ?? '';
              final catColor     = cat.isNotEmpty ? AppColor.categoryColor(cat) : AppColor.primary;
              final displayTitle = _title(tx);
              final dateStr      = tx['date'] != null
                  ? DateFormat('d MMM').format(DateTime.tryParse(tx['date'].toString()) ?? DateTime.now())
                  : '';

              return Column(
                children: [
                  if (idx > 0)
                    const Divider(height: 1, thickness: 0.5, color: AppColor.border, indent: 46),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Get.to(
                        () => TransactionDetailsScreen(transaction: tx, categoryList: categoryList),
                        transition: Transition.cupertino,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: PhosphorIcon(
                                _categoryIcon(cat, !isExpense),
                                size: 16, color: catColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayTitle,
                                    style: GoogleFonts.urbanist(
                                      color: AppColor.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  cat.isNotEmpty && cat != displayTitle ? '$cat · $dateStr' : dateStr,
                                  style: GoogleFonts.urbanist(color: AppColor.textTertiary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isExpense ? '−' : '+'}$sym${fmt.format((tx['amount'] as num).toDouble())}',
                            style: GoogleFonts.urbanist(
                              color: amtColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),

            if (filteredTx.length > 5) ...[
              const Divider(height: 1, thickness: 0.5, color: AppColor.border, indent: 46),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.to(
                    () => AllTransactionsScreen(initialType: viewType, initialMonth: month),
                    transition: Transition.cupertino,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      const SizedBox(width: 46),
                      Text('See all ${filteredTx.length} transactions',
                          style: GoogleFonts.urbanist(
                              color: AppColor.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const PhosphorIcon(PhosphorIconsLight.arrowRight, color: AppColor.primary, size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
