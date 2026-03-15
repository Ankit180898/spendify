import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/all_transaction_screen.dart';
import 'package:spendify/view/wallet/transaction_details_screen.dart';

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

    // Build a set of "yyyy-M" keys for months that have at least one transaction
    final allTx = Get.find<HomeController>().allTransactions;
    final activeMonths = <String>{};
    for (final t in allTx) {
      final d = DateTime.tryParse(t['date'] ?? '');
      if (d != null) activeMonths.add('${d.year}-${d.month}');
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? AppColor.darkCard : Colors.white;
        final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
        final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
        final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

        return StatefulBuilder(builder: (ctx, setLocal) {
          return Dialog(
            backgroundColor: bg,
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
                      Text('$pickerYear', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(
                        onPressed: pickerYear >= now.year ? null : () => setLocal(() => pickerYear++),
                        icon: PhosphorIcon(PhosphorIconsLight.caretRight,
                            color: pickerYear >= now.year ? textMuted.withValues(alpha: 0.3) : AppColor.primary, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    childAspectRatio: 2.0,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
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
                            color: isSelected ? AppColor.primary : (isDark ? AppColor.darkBg : const Color(0xFFF4F4F5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                months[i],
                                style: TextStyle(
                                  color: isFuture ? textMuted.withValues(alpha: 0.3) : (isSelected ? Colors.white : textPrimary),
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                width: 4,
                                height: 4,
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? AppColor.darkBg : Colors.white,
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            final controller = Get.find<HomeController>();
            final all = controller.allTransactions;
            final monthTx = _txForMonth(all, _month);

            final income = _sum(monthTx, 'income');
            final spent = _sum(monthTx, 'expense');
            final net = income - spent;

            final viewType = _tab.index == 0 ? 'expense' : 'income';
            final activeTotal = viewType == 'expense' ? spent : income;
            final activeColor =
                viewType == 'expense' ? AppColor.expense : AppColor.income;

            final cats = _categoryTotals(monthTx, viewType);
            final sorted = cats.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final filteredTx = monthTx
                .where((t) => t['type'] == viewType)
                .toList()
              ..sort((a, b) => DateTime.parse(b['date'])
                  .compareTo(DateTime.parse(a['date'])));

            final daysInMonth =
                DateTime(_month.year, _month.month + 1, 0).day;
            final dayMap = <int, double>{};
            for (final tx in monthTx) {
              if (tx['type'] != viewType) continue;
              final d = DateTime.parse(tx['date']).day;
              dayMap[d] =
                  (dayMap[d] ?? 0) + (tx['amount'] as num).toDouble();
            }
            final hasData = dayMap.isNotEmpty;
            final maxVal = hasData
                ? dayMap.values.reduce((a, b) => a > b ? a : b)
                : 1.0;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: _TopSection(
                    month: _month,
                    isDark: isDark,
                    tab: _tab,
                    onPrev: _prevMonth,
                    onNext: _nextMonth,
                    onMonthPick: _pickMonth,
                    canGoNext: !(_month.year == DateTime.now().year &&
                        _month.month == DateTime.now().month),
                    spent: spent,
                    income: income,
                    net: net,
                    activeTotal: activeTotal,
                    activeColor: activeColor,
                    viewType: viewType,
                    daysInMonth: daysInMonth,
                    dayMap: dayMap,
                    hasData: hasData,
                    maxVal: maxVal,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategoryBreakdown(
                    sorted: sorted,
                    total: activeTotal,
                    viewType: viewType,
                    isDark: isDark,
                    month: _month,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _TransactionsSection(
                    filteredTx: filteredTx,
                    viewType: viewType,
                    isDark: isDark,
                    month: _month,
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared icon helper — used by both categories and transactions
// ─────────────────────────────────────────────────────────────────────────────

PhosphorIconData _categoryIcon(String category, bool isIncome) {
  if (isIncome) return PhosphorIconsLight.wallet;
  final match = categoryList.firstWhere(
    (c) => c.name == category,
    orElse: () => CategoriesModel(name: category, icon: PhosphorIconsLight.tag),
  );
  return match.icon as PhosphorIconData;
}

// ─────────────────────────────────────────────────────────────────────────────
// Top section — stateful so sparkline can hold tap selection
// ─────────────────────────────────────────────────────────────────────────────

class _TopSection extends StatefulWidget {
  final DateTime month;
  final bool isDark;
  final TabController tab;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onMonthPick;
  final bool canGoNext;
  final double spent;
  final double income;
  final double net;
  final double activeTotal;
  final Color activeColor;
  final String viewType;
  final int daysInMonth;
  final Map<int, double> dayMap;
  final bool hasData;
  final double maxVal;

  const _TopSection({
    required this.month,
    required this.isDark,
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
    required this.hasData,
    required this.maxVal,
  });

  @override
  State<_TopSection> createState() => _TopSectionState();
}

class _TopSectionState extends State<_TopSection> {
  int? _selectedDay; // null = nothing selected

  @override
  void didUpdateWidget(_TopSection old) {
    super.didUpdateWidget(old);
    // Clear selection when tab or month changes
    if (old.viewType != widget.viewType || old.month != widget.month) {
      _selectedDay = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textMuted =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final textDim =
        isDark ? AppColor.textTertiary : AppColor.lightTextTertiary;
    final divider = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final segBg = isDark ? AppColor.darkCard : const Color(0xFFEEECE8);
    final tooltipBg = isDark ? AppColor.darkElevated : Colors.white;
    final fmt = NumberFormat('#,##0', 'en_IN');
    final sym = Get.find<HomeController>().currencySymbol.value;
    final isExpense = widget.viewType == 'expense';
    final isPositive = widget.net >= 0;
    final activeColor = widget.activeColor;
    final now = DateTime.now();

    // Tooltip text for selected day
    final selVal = _selectedDay != null ? (widget.dayMap[_selectedDay!] ?? 0) : 0.0;
    final selDate = _selectedDay != null
        ? DateTime(widget.month.year, widget.month.month, _selectedDay!)
        : null;
    final selLabel = selDate != null
        ? '${DateFormat('d MMM').format(selDate)}  ·  $sym${fmt.format(selVal)}'
        : null;

    return GestureDetector(
      // Tap anywhere outside bars clears selection
      onTap: () => setState(() => _selectedDay = null),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Month nav ──────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onPrev,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12, top: 4, bottom: 4),
                    child: PhosphorIcon(PhosphorIconsLight.caretLeft,
                        size: 15, color: AppColor.primary),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onMonthPick,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(widget.month),
                        style: TextStyle(
                            color: textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      const PhosphorIcon(PhosphorIconsLight.caretUpDown,
                          size: 12, color: AppColor.primary),
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
                        color: widget.canGoNext ? AppColor.primary : textDim),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Segmented control ──────────────────────────────
            Container(
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: segBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: widget.tab,
                indicator: BoxDecoration(
                  color: isDark ? AppColor.darkElevated : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.zero,
                tabs: [
                  Tab(
                    child: Text(
                      'Expenses',
                      style: TextStyle(
                        color: widget.tab.index == 0
                            ? AppColor.expense
                            : textMuted,
                        fontSize: 13,
                        fontWeight: widget.tab.index == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Income',
                      style: TextStyle(
                        color: widget.tab.index == 1
                            ? AppColor.income
                            : textMuted,
                        fontSize: 13,
                        fontWeight: widget.tab.index == 1
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Hero number ────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: double.infinity,
                key: ValueKey(widget.viewType),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$sym${fmt.format(widget.activeTotal)}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isExpense ? 'spent' : 'earned'} in ${DateFormat('MMMM').format(widget.month)}',
                      style: TextStyle(color: textDim, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Secondary stats ────────────────────────────────
            Row(
              children: [
                _InlineStat(
                  label: isExpense ? 'Income' : 'Expenses',
                  value: '$sym${fmt.format(isExpense ? widget.income : widget.spent)}',
                  color: isExpense ? AppColor.income : AppColor.expense,
                  textMuted: textMuted,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: divider,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _InlineStat(
                  label: isPositive ? 'Saved' : 'Over',
                  value: '$sym${fmt.format(widget.net.abs())}',
                  color: isPositive ? AppColor.income : AppColor.expense,
                  textMuted: textMuted,
                ),
                if (widget.income > 0 && widget.spent > 0) ...[
                  Container(
                    width: 1,
                    height: 28,
                    color: divider,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  _InlineStat(
                    label: 'Spend rate',
                    value:
                        '${(widget.spent / widget.income * 100).toStringAsFixed(0)}%',
                    color: textPrimary,
                    textMuted: textMuted,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // ── Sparkline header row: label + tooltip pill ─────
            Row(
              children: [
                Text(
                  'Daily ${isExpense ? 'spend' : 'income'}',
                  style: TextStyle(
                    color: textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                if (selLabel != null) ...[
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tooltipBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: activeColor.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Text(
                        selLabel,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // ── Sparkline bars ─────────────────────────────────
            // Extra 10px top padding so the "today" dot has room above the bar
            SizedBox(
              height: 66, // 46 bar + 10 dot zone + 10 top buffer
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(widget.daysInMonth, (i) {
                  final day = i + 1;
                  final val = widget.dayMap[day] ?? 0;
                  final frac = val > 0 ? val / widget.maxVal : 0.0;
                  final isToday = day == now.day &&
                      widget.month.month == now.month &&
                      widget.month.year == now.year;
                  final isSelected = _selectedDay == day;
                  final hasValue = val > 0;

                  // Bar opacity: selected = full, rest dim slightly; today always full
                  final barAlpha = _selectedDay == null
                      ? (isToday ? 1.0 : 0.55)
                      : (isSelected ? 1.0 : 0.25);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!hasValue) return; // can't select empty bars
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedDay = isSelected ? null : day;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Today dot — 4px circle above bar, only for current month
                            SizedBox(
                              height: 10,
                              child: Center(
                                child: isToday
                                    ? Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: activeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            // The bar itself
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: hasValue
                                  ? (frac * 46).clamp(3.0, 46.0)
                                  : 3,
                              decoration: BoxDecoration(
                                color: hasValue
                                    ? activeColor.withValues(alpha: barAlpha)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.04)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Axis labels ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['1', '7', '14', '21', '${widget.daysInMonth}']
                  .map((l) =>
                      Text(l, style: TextStyle(color: textDim, fontSize: 10)))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Divider(height: 1, thickness: 0.5, color: divider),
          ],
        ),
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textMuted;

  const _InlineStat({
    required this.label,
    required this.value,
    required this.color,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: textMuted, fontSize: 11, fontWeight: FontWeight.w400)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category breakdown
// Each category gets a shade of the tab's accent color (expense = coral family,
// income = mint family) so the stacked bar and row bars always feel cohesive.
// ─────────────────────────────────────────────────────────────────────────────

// Returns an ordered list of colors for N categories, all within the tab hue.
List<Color> _tabPalette(String viewType, int count) {
  // Expense: coral-red family.  Income: mint-green family.
  final isExpense = viewType == 'expense';

  // Define 6 stops per family — enough for top-5 + tail
  final List<Color> palette = isExpense
      ? const [
          Color(0xFFFF5370), // coral (AppColor.expense)
          Color(0xFFFF7A5C),
          Color(0xFFFF9A6C),
          Color(0xFFFFB88A),
          Color(0xFFFFD0A8),
          Color(0xFFFFE8CC),
        ]
      : const [
          Color(0xFF00C896), // mint (AppColor.income)
          Color(0xFF26D4A4),
          Color(0xFF4DDEB4),
          Color(0xFF80E8C8),
          Color(0xFFAAF0DA),
          Color(0xFFCCF7EC),
        ];

  return List.generate(count, (i) => palette[i.clamp(0, palette.length - 1)]);
}

class _CategoryBreakdown extends StatefulWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  final String viewType;
  final bool isDark;
  final DateTime month;

  const _CategoryBreakdown({
    required this.sorted,
    required this.total,
    required this.viewType,
    required this.isDark,
    required this.month,
  });

  @override
  State<_CategoryBreakdown> createState() => _CategoryBreakdownState();
}

class _CategoryBreakdownState extends State<_CategoryBreakdown> {
  bool _showAll = false;

  @override
  void didUpdateWidget(_CategoryBreakdown old) {
    super.didUpdateWidget(old);
    // Reset when month/type changes
    if (old.month != widget.month || old.viewType != widget.viewType) {
      _showAll = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = widget.sorted;
    final total = widget.total;
    final viewType = widget.viewType;
    final isDark = widget.isDark;
    final month = widget.month;

    final textMuted =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final divider = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final sym = Get.find<HomeController>().currencySymbol.value;
    final fmt = NumberFormat('#,##0', 'en_IN');
    final isExpense = viewType == 'expense';
    final top5 = sorted.take(5).toList();
    final visible = _showAll ? sorted : top5;

    // One palette call — same colors used in bar AND rows
    final colors = _tabPalette(viewType, visible.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),

          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          isExpense ? PhosphorIconsLight.chartPie : PhosphorIconsLight.trendUp,
                          color: textMuted.withValues(alpha: 0.35),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No ${isExpense ? 'expense' : 'income'} categories this month',
                      style: TextStyle(color: textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // ── Stacked proportion bar ────────────────────────
            // Uses tab-palette colors so bar segments visually match the rows
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    ...visible.asMap().entries.map((e) {
                      final flex = total > 0
                          ? (e.value.value / total * 1000).round()
                          : 0;
                      return Flexible(
                        flex: flex < 1 ? 1 : flex,
                        child: Container(color: colors[e.key]),
                      );
                    }),
                    if (!_showAll && sorted.length > 5)
                      Flexible(
                        flex: sorted.skip(5).fold<int>(
                              0,
                              (s, e) => s +
                                  (total > 0
                                      ? (e.value / total * 1000).round()
                                      : 0),
                            ),
                        child: Container(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // ── Category rows ─────────────────────────────────
            ...visible.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final pct = total > 0 ? cat.value / total : 0.0;
              final color = colors[i];

              return _CategoryRow(
                name: cat.key,
                amount: '$sym${fmt.format(cat.value)}',
                pct: pct,
                color: color,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                isExpense: isExpense,
                dividerColor: divider,
                showDivider: i < visible.length - 1 || (!_showAll && sorted.length > 5),
                onTap: () => Get.to(
                  () => AllTransactionsScreen(
                    initialType: viewType,
                    initialMonth: month,
                    initialCategory: cat.key,
                  ),
                  transition: Transition.cupertino,
                ),
              );
            }),

            if (!_showAll && sorted.length > 5)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showAll = true);
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    '+ ${sorted.length - 5} more categories',
                    style: const TextStyle(
                      color: AppColor.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            if (_showAll && sorted.length > 5)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showAll = false);
                },
                child: const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    'Show less',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
          Divider(height: 1, thickness: 0.5, color: divider),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final String amount;
  final double pct;
  final Color color;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final bool isExpense;
  final Color dividerColor;
  final bool showDivider;
  final VoidCallback? onTap;

  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.pct,
    required this.color,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.isExpense,
    required this.dividerColor,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final track = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              // Icon circle — tinted with row color
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.16 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(
                    _categoryIcon(name, !isExpense),
                    size: 15,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Stack(
                      children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: track,
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

              // Amount + percentage stacked right-aligned
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: dividerColor,
            indent: 46,
          ),
      ],
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transactions — Phosphor icons, filtered by tab
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionsSection extends StatelessWidget {
  final List<Map<String, dynamic>> filteredTx;
  final String viewType;
  final bool isDark;
  final DateTime month;

  const _TransactionsSection({
    required this.filteredTx,
    required this.viewType,
    required this.isDark,
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
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textMuted =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final textDim =
        isDark ? AppColor.textTertiary : AppColor.lightTextTertiary;
    final divColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final sym = Get.find<HomeController>().currencySymbol.value;
    final isExpense = viewType == 'expense';
    final amountColor = isExpense ? AppColor.expense : AppColor.income;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isExpense ? 'Expenses' : 'Income',
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),

          if (filteredTx.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          PhosphorIconsLight.receipt,
                          color: textMuted.withValues(alpha: 0.35),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No ${isExpense ? 'expenses' : 'income'} this month',
                      style: TextStyle(color: textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...filteredTx.take(5).toList().asMap().entries.map((e) {
              final idx = e.key;
              final tx = e.value;
              final cat = (tx['category'] as String?) ?? '';
              final catColor = cat.isNotEmpty
                  ? AppColor.categoryColor(cat)
                  : AppColor.primary;
              final displayTitle = _title(tx);

              return Column(
                children: [
                  if (idx > 0)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: divColor,
                      indent: 46,
                    ),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Get.to(
                        () => TransactionDetailsScreen(
                            transaction: tx, categoryList: categoryList),
                        transition: Transition.cupertino,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: PhosphorIcon(
                                _categoryIcon(cat, !isExpense),
                                size: 15,
                                color: catColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayTitle,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (cat.isNotEmpty && cat != displayTitle)
                                  Text(cat,
                                      style: TextStyle(
                                        color: textDim,
                                        fontSize: 11,
                                      )),
                              ],
                            ),
                          ),
                          Text(
                            '${isExpense ? '−' : '+'}$sym${fmt.format((tx['amount'] as num).toDouble())}',
                            style: TextStyle(
                              color: amountColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
              Divider(height: 1, thickness: 0.5, color: divColor, indent: 46),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.to(
                    () => AllTransactionsScreen(
                      initialType: viewType,
                      initialMonth: month,
                    ),
                    transition: Transition.cupertino,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      const SizedBox(width: 46),
                      Text(
                        'See all ${filteredTx.length} transactions',
                        style: const TextStyle(
                          color: AppColor.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const PhosphorIcon(PhosphorIconsLight.arrowRight,
                          color: AppColor.primary, size: 13),
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