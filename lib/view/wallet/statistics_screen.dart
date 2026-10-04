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
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/all_transaction_screen.dart';
import 'package:spendify/view/wallet/transaction_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

const _catIcons = <String, Object>{
  'Food & Drinks': PhosphorIconsDuotone.forkKnife,
  'Groceries': PhosphorIconsDuotone.shoppingCart,
  'Transport': PhosphorIconsDuotone.bus,
  'Car': PhosphorIconsDuotone.car,
  'Shopping': PhosphorIconsDuotone.shoppingBag,
  'Bills & Fees': PhosphorIconsDuotone.lightning,
  'Health': PhosphorIconsDuotone.heartbeat,
  'Entertainment': PhosphorIconsDuotone.filmSlate,
  'Travel': PhosphorIconsDuotone.airplaneTilt,
  'Investments': PhosphorIconsDuotone.trendUp,
  'Education': PhosphorIconsDuotone.graduationCap,
  'Subscriptions': PhosphorIconsDuotone.repeat,
  'Gifts': PhosphorIconsDuotone.gift,
  'Salary': PhosphorIconsDuotone.briefcase,
  'Freelance': PhosphorIconsDuotone.laptop,
  'Business': PhosphorIconsDuotone.storefront,
  'Interest': PhosphorIconsDuotone.percent,
  'Refund': PhosphorIconsDuotone.arrowCounterClockwise,
};

Object _categoryIcon(String category, bool isIncome) =>
    _catIcons[category] ?? (isIncome ? PhosphorIconsDuotone.arrowCircleDown : PhosphorIconsDuotone.tag);

DateTime? _dateOf(Map<String, dynamic> t) =>
    t['parsedDate'] as DateTime? ?? DateTime.tryParse(t['date'] ?? '');

double _amt(Map<String, dynamic> t) => (t['amount'] as num?)?.toDouble() ?? 0;

String _short(double v, String sym) {
  final a = v.abs();
  if (a >= 100000) return '$sym${(a / 100000).toStringAsFixed(1)}L';
  if (a >= 1000) return '$sym${(a / 1000).toStringAsFixed(1)}K';
  return '$sym${NumberFormat('#,##0', 'en_IN').format(a)}';
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _SectionTitle(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
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
            if (trailing != null) trailing!,
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _month;
  String _viewType = 'expense';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shiftMonth(int delta) {
    if (delta > 0 && _isCurrentMonth) return;
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    var year = _month.year;
    final active = <String>{};
    for (final t in Get.find<HomeController>().allTransactions) {
      final d = _dateOf(t);
      if (d != null) active.add('${d.year}-${d.month}');
    }
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setLocal(() => year--),
                    icon: const PhosphorIcon(PhosphorIconsBold.caretLeft,
                        size: 16, color: AppColor.textSecondary),
                  ),
                  Expanded(
                    child: Text(
                      '$year',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                    ),
                  ),
                  IconButton(
                    onPressed: year >= now.year ? null : () => setLocal(() => year++),
                    icon: PhosphorIcon(PhosphorIconsBold.caretRight,
                        size: 16,
                        color: year >= now.year ? AppColor.border : AppColor.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
                children: List.generate(12, (i) {
                  final future = year == now.year && i + 1 > now.month;
                  final selected = year == _month.year && i + 1 == _month.month;
                  final hasData = active.contains('$year-${i + 1}');
                  return GestureDetector(
                    onTap: future
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _month = DateTime(year, i + 1));
                            Navigator.of(ctx).pop();
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected ? AppColor.primary : AppColor.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: selected ? AppColor.primary : AppColor.borderStrong),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            names[i],
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                              color: future
                                  ? AppColor.textTertiary.withValues(alpha: 0.5)
                                  : selected
                                      ? Colors.white
                                      : AppColor.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasData && !future
                                  ? (selected ? Colors.white : AppColor.warning)
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
      ),
    );
  }

  List<Map<String, dynamic>> _between(List<Map<String, dynamic>> all, DateTime from, DateTime to) =>
      all.where((t) {
        final d = _dateOf(t);
        return d != null && !d.isBefore(from) && d.isBefore(to);
      }).toList();

  double _sum(List<Map<String, dynamic>> list, String type) =>
      list.where((t) => t['type'] == type).fold(0.0, (s, t) => s + _amt(t));

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.bg,
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            final ctrl = Get.find<HomeController>();
            final sym = ctrl.currencySymbol.value;
            final all = ctrl.allTransactions.toList();
            final now = DateTime.now();

            final monthStart = DateTime(_month.year, _month.month, 1);
            final monthEnd = DateTime(_month.year, _month.month + 1, 1);
            final monthTx = _between(all, monthStart, monthEnd);

            final income = _sum(monthTx, 'income');
            final spent = _sum(monthTx, 'expense');
            final net = income - spent;
            final isExpense = _viewType == 'expense';
            final activeTotal = isExpense ? spent : income;

            // Fair comparison: for the current month compare the same number
            // of days last month; past months compare the whole month.
            final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
            final daysElapsed = _isCurrentMonth ? now.day : daysInMonth;
            final prevStart = DateTime(_month.year, _month.month - 1, 1);
            final prevLen = DateTime(_month.year, _month.month, 0).day;
            final prevEnd = DateTime(prevStart.year, prevStart.month, math.min(daysElapsed, prevLen))
                .add(const Duration(days: 1));
            final prevTotal = _sum(_between(all, prevStart, prevEnd), _viewType);

            final dayMap = <int, double>{};
            for (final t in monthTx) {
              if (t['type'] != _viewType) continue;
              final d = _dateOf(t)?.day;
              if (d != null) dayMap[d] = (dayMap[d] ?? 0) + _amt(t);
            }

            final cats = <String, double>{};
            for (final t in monthTx) {
              if (t['type'] != _viewType) continue;
              final c = (t['category'] as String?)?.trim();
              final key = (c == null || c.isEmpty) ? 'Others' : c;
              cats[key] = (cats[key] ?? 0) + _amt(t);
            }
            final sortedCats = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

            final txs = monthTx.where((t) => t['type'] == _viewType).toList()
              ..sort((a, b) => (_dateOf(b) ?? DateTime(0)).compareTo(_dateOf(a) ?? DateTime(0)));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    month: _month,
                    canGoNext: !_isCurrentMonth,
                    onPrev: () => _shiftMonth(-1),
                    onNext: () => _shiftMonth(1),
                    onPick: _pickMonth,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _TypeSwitch(
                    isExpense: isExpense,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _viewType = v ? 'expense' : 'income');
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HeroCard(
                    month: _month,
                    viewType: _viewType,
                    total: activeTotal,
                    prevTotal: prevTotal,
                    comparedDays: _isCurrentMonth ? daysElapsed : null,
                    dayMap: dayMap,
                    daysInMonth: daysInMonth,
                    todayDay: _isCurrentMonth ? now.day : null,
                    sym: sym,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Overview(
                    isExpense: isExpense,
                    income: income,
                    spent: spent,
                    net: net,
                    activeTotal: activeTotal,
                    daysElapsed: daysElapsed,
                    sym: sym,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategorySection(
                    sorted: sortedCats,
                    total: activeTotal,
                    viewType: _viewType,
                    month: _month,
                    sym: sym,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _TransactionSection(
                    txs: txs,
                    viewType: _viewType,
                    month: _month,
                    sym: sym,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        AppDimens.navBarHeight +
                        AppDimens.spaceXXL,
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
// Header — title + month switcher
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrev, onNext, onPick;

  const _Header({
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics',
                    style: GoogleFonts.urbanist(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  Text(
                    'Where your money came and went',
                    style: GoogleFonts.urbanist(fontSize: 13, color: AppColor.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColor.borderStrong),
              ),
              child: Row(
                children: [
                  _NavArrow(icon: PhosphorIconsBold.caretLeft, onTap: onPrev),
                  GestureDetector(
                    onTap: onPick,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        DateFormat('MMM yyyy').format(month),
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  _NavArrow(
                    icon: PhosphorIconsBold.caretRight,
                    onTap: canGoNext ? onNext : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _NavArrow extends StatelessWidget {
  final PhosphorIconData icon;
  final VoidCallback? onTap;
  const _NavArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 34,
          height: 40,
          child: Center(
            child: PhosphorIcon(icon,
                size: 13, color: onTap == null ? AppColor.border : AppColor.textSecondary),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Expenses / Income switch
// ─────────────────────────────────────────────────────────────────────────────

class _TypeSwitch extends StatelessWidget {
  final bool isExpense;
  final ValueChanged<bool> onChanged;
  const _TypeSwitch({required this.isExpense, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColor.surfaceVariant,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: isExpense ? Alignment.centerLeft : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(color: AppColor.primary.withValues(alpha: 0.12), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (label, value, color) in [
                    ('Expenses', true, AppColor.expense),
                    ('Income', false, AppColor.income),
                  ])
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(value),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isExpense == value
                                      ? color
                                      : AppColor.textTertiary.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  height: 1,
                                  fontWeight: isExpense == value ? FontWeight.w700 : FontWeight.w500,
                                  color: isExpense == value
                                      ? AppColor.textPrimary
                                      : AppColor.textSecondary,
                                ),
                              ),
                            ],
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero card — total, fair comparison, cumulative chart
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatefulWidget {
  final DateTime month;
  final String viewType;
  final double total;
  final double prevTotal;
  final int? comparedDays; // null = whole month
  final Map<int, double> dayMap;
  final int daysInMonth;
  final int? todayDay;
  final String sym;

  const _HeroCard({
    required this.month,
    required this.viewType,
    required this.total,
    required this.prevTotal,
    required this.comparedDays,
    required this.dayMap,
    required this.daysInMonth,
    required this.todayDay,
    required this.sym,
  });

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  int? _selectedDay;

  @override
  void didUpdateWidget(_HeroCard old) {
    super.didUpdateWidget(old);
    if (old.viewType != widget.viewType || old.month != widget.month) _selectedDay = null;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final isExpense = widget.viewType == 'expense';
    final accent = isExpense ? AppColor.primary : AppColor.income;

    // Only plot up to today for the current month
    final lastDay = widget.todayDay ?? widget.daysInMonth;
    double cum = 0;
    final points = List.generate(lastDay, (i) {
      cum += widget.dayMap[i + 1] ?? 0;
      return cum;
    });
    final maxCum = points.isEmpty ? 0.0 : points.reduce(math.max);
    final hasData = maxCum > 0;

    final hasPrev = widget.prevTotal > 0;
    final pct = hasPrev ? (widget.total - widget.prevTotal) / widget.prevTotal * 100 : 0.0;
    final up = pct >= 0;
    // More spending = warning; more income = good
    final good = isExpense ? !up : up;
    final chipColor = good ? AppColor.income : AppColor.expense;

    final sel = _selectedDay;
    final selLabel = sel == null
        ? null
        : '${DateFormat('d MMM').format(DateTime(widget.month.year, widget.month.month, sel))} · '
            '${widget.sym}${fmt.format(widget.dayMap[sel] ?? 0)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        decoration: BoxDecoration(
          color: AppColor.bannerBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isExpense ? 'Spent' : 'Earned'} in ${DateFormat('MMMM').format(widget.month)}',
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColor.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              key: ValueKey('${widget.viewType}-${widget.month}'),
              tween: Tween(begin: 0, end: widget.total),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${widget.sym}${fmt.format(v)}',
                  style: GoogleFonts.urbanist(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                    letterSpacing: -1.2,
                    height: 1.05,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (hasPrev)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColor.surface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      up ? PhosphorIconsBold.trendUp : PhosphorIconsBold.trendDown,
                      size: 12,
                      color: chipColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pct.abs().toStringAsFixed(0)}% ${up ? 'more' : 'less'}',
                      style: GoogleFonts.urbanist(
                          fontSize: 12, fontWeight: FontWeight.w700, color: chipColor),
                    ),
                    Text(
                      widget.comparedDays != null
                          ? ' than the first ${widget.comparedDays} days of last month'
                          : ' than last month',
                      style: GoogleFonts.urbanist(fontSize: 12, color: AppColor.textSecondary),
                    ),
                  ],
                ),
              )
            else
              Text(
                'No ${isExpense ? 'spending' : 'income'} logged last month to compare',
                style: GoogleFonts.urbanist(fontSize: 12, color: AppColor.textTertiary),
              ),
            const SizedBox(height: 14),
            if (hasData) ...[
              SizedBox(
                height: 140,
                child: _AreaChart(
                  points: points,
                  maxCum: maxCum,
                  daysInMonth: widget.daysInMonth,
                  color: accent,
                  selectedDay: _selectedDay,
                  onDaySelected: (d) => setState(() => _selectedDay = d),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final d in [1, 8, 15, 22, widget.daysInMonth])
                    Expanded(
                      child: Text(
                        '$d',
                        textAlign: d == 1
                            ? TextAlign.left
                            : d == widget.daysInMonth
                                ? TextAlign.right
                                : TextAlign.center,
                        style: GoogleFonts.urbanist(fontSize: 10, color: AppColor.textTertiary),
                      ),
                    ),
                ],
              ),
              SizedBox(
                height: 24,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      selLabel ?? 'Tap or drag the chart to see a day',
                      key: ValueKey(selLabel),
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: selLabel != null ? FontWeight.w700 : FontWeight.w500,
                        color: selLabel != null ? AppColor.textPrimary : AppColor.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColor.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(PhosphorIconsDuotone.chartLine,
                        size: 28, color: AppColor.primary, duotoneSecondaryOpacity: 0.3),
                    const SizedBox(height: 6),
                    Text(
                      'No ${isExpense ? 'expenses' : 'income'} this month yet',
                      style: GoogleFonts.urbanist(fontSize: 13, color: AppColor.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AreaChart extends StatelessWidget {
  final List<double> points;
  final double maxCum;
  final int daysInMonth;
  final Color color;
  final int? selectedDay;
  final ValueChanged<int?> onDaySelected;

  const _AreaChart({
    required this.points,
    required this.maxCum,
    required this.daysInMonth,
    required this.color,
    required this.selectedDay,
    required this.onDaySelected,
  });

  int _dayAt(double dx, double width) {
    final day = ((dx / width).clamp(0.0, 1.0) * (daysInMonth - 1)).round() + 1;
    return day.clamp(1, points.length);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onDaySelected(_dayAt(d.localPosition.dx, w)),
          onPanUpdate: (d) => onDaySelected(_dayAt(d.localPosition.dx, w)),
          onTapUp: (_) => Future.delayed(const Duration(seconds: 2), () => onDaySelected(null)),
          onPanEnd: (_) => Future.delayed(const Duration(seconds: 2), () => onDaySelected(null)),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, t, __) => CustomPaint(
              size: Size(w, c.maxHeight),
              painter: _AreaPainter(
                points: points,
                maxCum: maxCum,
                daysInMonth: daysInMonth,
                color: color,
                selectedIndex: selectedDay != null ? selectedDay! - 1 : null,
                progress: t,
              ),
            ),
          ),
        );
      });
}

class _AreaPainter extends CustomPainter {
  final List<double> points;
  final double maxCum;
  final int daysInMonth;
  final Color color;
  final int? selectedIndex;
  final double progress;

  const _AreaPainter({
    required this.points,
    required this.maxCum,
    required this.daysInMonth,
    required this.color,
    required this.selectedIndex,
    required this.progress,
  });

  List<Offset> _pixels(Size size) {
    const padV = 10.0;
    return List.generate(points.length, (i) {
      final x = daysInMonth <= 1 ? 0.0 : i / (daysInMonth - 1) * size.width;
      final norm = maxCum > 0 ? points[i] / maxCum : 0.0;
      final y = padV + (1 - norm * progress) * (size.height - padV * 2);
      return Offset(x, y);
    });
  }

  Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final p0 = i > 0 ? p[i - 1] : p[i];
      final p1 = p[i];
      final p2 = p[i + 1];
      final p3 = i < p.length - 2 ? p[i + 2] : p2;
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final px = _pixels(size);

    // Faint horizontal guides
    final guide = Paint()
      ..color = AppColor.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }

    if (px.length == 1) {
      canvas.drawCircle(px.first, 4, Paint()..color = color);
      return;
    }

    final line = _smooth(px);
    final fill = Path.from(line)
      ..lineTo(px.last.dx, size.height)
      ..lineTo(px.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // End-of-line dot (today / last day) and selected-day marker
    final dotIdx = selectedIndex ?? px.length - 1;
    if (dotIdx >= 0 && dotIdx < px.length) {
      final p = px[dotIdx];
      if (selectedIndex != null) {
        final dash = Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 1;
        for (double y = 0; y < size.height; y += 7) {
          canvas.drawLine(Offset(p.dx, y), Offset(p.dx, math.min(y + 3.5, size.height)), dash);
        }
      }
      canvas.drawCircle(p, 7, Paint()..color = color.withValues(alpha: 0.2));
      canvas.drawCircle(p, 4.5, Paint()..color = AppColor.surface);
      canvas.drawCircle(p, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_AreaPainter old) =>
      old.points != points ||
      old.color != color ||
      old.selectedIndex != selectedIndex ||
      old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview tiles
// ─────────────────────────────────────────────────────────────────────────────

class _Overview extends StatelessWidget {
  final bool isExpense;
  final double income, spent, net, activeTotal;
  final int daysElapsed;
  final String sym;

  const _Overview({
    required this.isExpense,
    required this.income,
    required this.spent,
    required this.net,
    required this.activeTotal,
    required this.daysElapsed,
    required this.sym,
  });

  @override
  Widget build(BuildContext context) {
    final saved = net >= 0;
    final perDay = daysElapsed > 0 ? activeTotal / daysElapsed : 0.0;
    final rate = income > 0 ? (spent / income * 100).round() : null;

    final tiles = [
      _Tile(
        icon: isExpense ? PhosphorIconsDuotone.arrowDownLeft : PhosphorIconsDuotone.arrowUpRight,
        color: isExpense ? AppColor.income : AppColor.expense,
        label: isExpense ? 'Income' : 'Spent',
        value: _short(isExpense ? income : spent, sym),
      ),
      _Tile(
        icon: saved ? PhosphorIconsDuotone.piggyBank : PhosphorIconsDuotone.warningCircle,
        color: saved ? AppColor.income : AppColor.expense,
        label: saved ? 'Saved' : 'Overspent',
        value: _short(net, sym),
      ),
      _Tile(
        icon: PhosphorIconsDuotone.calendarBlank,
        color: AppColor.catCar,
        label: isExpense ? 'Per day' : 'Per day earned',
        value: _short(perDay, sym),
      ),
      _Tile(
        icon: PhosphorIconsDuotone.chartPieSlice,
        color: AppColor.warning,
        label: 'Spend rate',
        value: rate == null ? '—' : '$rate%',
        hint: rate == null ? 'No income yet' : 'of income',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.3,
        padding: EdgeInsets.zero,
        children: tiles,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Object icon;
  final Color color;
  final String label;
  final String value;
  final String? hint;

  const _Tile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.borderStrong),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: PhosphorIcon(icon, size: 17, color: color, duotoneSecondaryOpacity: 0.3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hint != null ? '$label · $hint' : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.urbanist(fontSize: 11, color: AppColor.textTertiary),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
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
// Categories — donut + rows
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySection extends StatefulWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  final String viewType;
  final DateTime month;
  final String sym;

  const _CategorySection({
    required this.sorted,
    required this.total,
    required this.viewType,
    required this.month,
    required this.sym,
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
    final sorted = widget.sorted;
    final total = widget.total;
    final isExpense = widget.viewType == 'expense';
    final fmt = NumberFormat('#,##0', 'en_IN');
    final visible = _showAll ? sorted : sorted.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          'By category',
          trailing: sorted.isEmpty
              ? null
              : Text('${sorted.length} ${sorted.length == 1 ? 'category' : 'categories'}',
                  style: AppTypography.caption(AppColor.textTertiary)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColor.borderStrong),
            ),
            child: sorted.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          PhosphorIcon(PhosphorIconsDuotone.chartPieSlice,
                              size: 30, color: AppColor.primary, duotoneSecondaryOpacity: 0.3),
                          const SizedBox(height: 8),
                          Text('No ${isExpense ? 'expense' : 'income'} categories this month',
                              style: AppTypography.body(AppColor.textSecondary)),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Donut + top category
                      Row(
                        children: [
                          SizedBox(
                            width: 112,
                            height: 112,
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey('${widget.viewType}-${widget.month}'),
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (_, t, __) => CustomPaint(
                                painter: _DonutPainter(
                                  values: sorted.map((e) => e.value).toList(),
                                  colors: sorted.map((e) => AppColor.categoryColor(e.key)).toList(),
                                  progress: t,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${sorted.length}',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: AppColor.textPrimary,
                                        ),
                                      ),
                                      Text('categories',
                                          style: GoogleFonts.urbanist(
                                              fontSize: 10, color: AppColor.textTertiary)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isExpense ? 'Biggest spend' : 'Top source',
                                    style: AppTypography.caption(AppColor.textTertiary)),
                                const SizedBox(height: 2),
                                Text(
                                  sorted.first.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${widget.sym}${fmt.format(sorted.first.value)} · '
                                  '${total > 0 ? (sorted.first.value / total * 100).round() : 0}% of total',
                                  style: AppTypography.caption(AppColor.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColor.border),
                      for (var i = 0; i < visible.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColor.border, indent: 52),
                        _CategoryRow(
                          name: visible[i].key,
                          amount: visible[i].value,
                          pct: total > 0 ? visible[i].value / total : 0,
                          isIncome: !isExpense,
                          sym: widget.sym,
                          onTap: () => Get.to(
                            () => AllTransactionsScreen(
                              initialType: widget.viewType,
                              initialMonth: widget.month,
                              initialCategory: visible[i].key,
                            ),
                            transition: Transition.cupertino,
                          ),
                        ),
                      ],
                      if (sorted.length > 5) ...[
                        const Divider(height: 1, color: AppColor.border),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showAll = !_showAll);
                          },
                          child: Text(
                            _showAll ? 'Show less' : 'Show ${sorted.length - 5} more',
                            style: AppTypography.captionSemiBold(AppColor.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final double amount;
  final double pct;
  final bool isIncome;
  final String sym;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.pct,
    required this.isIncome,
    required this.sym,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColor.categoryColor(name);
    final fmt = NumberFormat('#,##0', 'en_IN');
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: PhosphorIcon(_categoryIcon(name, isIncome),
                    size: 19, color: color, duotoneSecondaryOpacity: 0.3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySemiBold(AppColor.textPrimary),
                        ),
                      ),
                      Text(
                        '$sym${fmt.format(amount)}',
                        style: AppTypography.bodySemiBoldTabular(AppColor.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: v,
                              minHeight: 5,
                              backgroundColor: AppColor.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${(pct * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: AppTypography.caption(AppColor.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double progress;

  const _DonutPainter({required this.values, required this.colors, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (s, v) => s + v);
    if (total <= 0) return;
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    canvas.drawArc(arcRect, 0, 2 * math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = AppColor.surfaceVariant);

    const gap = 0.04; // radians between slices
    var start = -math.pi / 2;
    final sweepTotal = 2 * math.pi * progress;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * sweepTotal;
      final drawn = values.length > 1 ? math.max(0.0, sweep - gap) : sweep;
      if (drawn > 0) {
        canvas.drawArc(
          arcRect,
          start,
          drawn,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.butt
            ..color = colors[i],
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.values != values || old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent transactions for the month
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionSection extends StatelessWidget {
  final List<Map<String, dynamic>> txs;
  final String viewType;
  final DateTime month;
  final String sym;

  const _TransactionSection({
    required this.txs,
    required this.viewType,
    required this.month,
    required this.sym,
  });

  String _title(Map<String, dynamic> tx) {
    final t = (tx['description'] as String?)?.trim();
    if (t != null && t.isNotEmpty) return t;
    final cat = (tx['category'] as String?) ?? '';
    if (cat.isNotEmpty) return cat;
    return tx['type'] == 'income' ? 'Income' : 'Expense';
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = viewType == 'expense';
    final fmt = NumberFormat('#,##0.##', 'en_IN');
    void seeAll() => Get.to(
          () => AllTransactionsScreen(initialType: viewType, initialMonth: month),
          transition: Transition.cupertino,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          isExpense ? 'Latest expenses' : 'Latest income',
          trailing: txs.length > 5
              ? GestureDetector(
                  onTap: seeAll,
                  child: Text('See all ${txs.length}',
                      style: AppTypography.captionSemiBold(AppColor.primary)),
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColor.borderStrong),
            ),
            child: txs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Column(
                        children: [
                          PhosphorIcon(PhosphorIconsDuotone.receipt,
                              size: 30, color: AppColor.primary, duotoneSecondaryOpacity: 0.3),
                          const SizedBox(height: 8),
                          Text('No ${isExpense ? 'expenses' : 'income'} this month',
                              style: AppTypography.body(AppColor.textSecondary)),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < math.min(5, txs.length); i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColor.border, indent: 64, endIndent: 14),
                        _TxRow(
                          tx: txs[i],
                          title: _title(txs[i]),
                          isExpense: isExpense,
                          sym: sym,
                          fmt: fmt,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String title;
  final bool isExpense;
  final String sym;
  final NumberFormat fmt;

  const _TxRow({
    required this.tx,
    required this.title,
    required this.isExpense,
    required this.sym,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final cat = (tx['category'] as String?) ?? '';
    final color = cat.isNotEmpty ? AppColor.categoryColor(cat) : AppColor.primary;
    final d = _dateOf(tx);
    final date = d != null ? DateFormat('d MMM').format(d) : '';
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.to(
          () => TransactionDetailsScreen(transaction: tx, categoryList: categoryList),
          transition: Transition.cupertino,
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: PhosphorIcon(_categoryIcon(cat, !isExpense),
                    size: 18, color: color, duotoneSecondaryOpacity: 0.3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySemiBold(AppColor.textPrimary)),
                  Text(
                    cat.isNotEmpty && cat != title ? '$cat · $date' : date,
                    style: AppTypography.caption(AppColor.textTertiary),
                  ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '−' : '+'}$sym${fmt.format(_amt(tx))}',
              style: AppTypography.bodySemiBoldTabular(
                  isExpense ? AppColor.textPrimary : AppColor.income),
            ),
          ],
        ),
      ),
    );
  }
}
