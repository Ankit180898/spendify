import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/all_transaction/all_transaction_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/add_transaction_screen.dart';
import 'package:spendify/view/wallet/transaction_list_item.dart';

class AllTransactionsScreen extends StatefulWidget {
  final String initialType; // 'income', 'expense', or '' for all
  final DateTime? initialMonth; // when set, pre-filter to that month
  final String initialCategory; // when set, pre-filter to that category
  const AllTransactionsScreen({super.key, this.initialType = '', this.initialMonth, this.initialCategory = ''});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final controller = Get.put(AllTransactionsController());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _calendarVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMonth != null) {
      controller.specificMonth.value = widget.initialMonth;
    }
    if (widget.initialType.isNotEmpty) {
      controller.typeFilter.value = widget.initialType;
    }
    if (widget.initialCategory.isNotEmpty) {
      controller.isSelected.value = true;
      controller.selectedChip.value = widget.initialCategory;
    }
    if (widget.initialMonth != null || widget.initialType.isNotEmpty || widget.initialCategory.isNotEmpty) {
      controller.filterTransactions(controller.selectedFilter.value);
    }
    _scrollController.addListener(() {
      if (controller.hasMore.value) {
        final pos = _scrollController.position;
        if (pos.pixels >= pos.maxScrollExtent - 300) {
          controller.loadMore();
        }
      }
    });
  }

  @override
  void dispose() {
    controller.typeFilter.value = '';
    controller.specificMonth.value = null;
    controller.searchQuery.value = '';
    controller.selectedChip.value = '';
    controller.isSelected.value = false;
    _scrollController.dispose();
    _searchController.dispose();
    Get.delete<AllTransactionsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const PhosphorIcon(PhosphorIconsLight.arrowLeft,
                        color: AppColor.textPrimary, size: 22),
                  ),
                  Expanded(
                    child: Text(
                      widget.initialMonth != null
                          ? DateFormat('MMMM yyyy').format(widget.initialMonth!)
                          : 'Transactions',
                      style: GoogleFonts.urbanist(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Obx(() {
                    final hasDay = controller.selectedDay.value != null;
                    final active = _calendarVisible || hasDay;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _calendarVisible = !_calendarVisible);
                        if (!_calendarVisible) controller.clearDayFilter();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: active ? AppColor.primary : AppColor.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: active ? AppColor.primary : AppColor.borderStrong),
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            PhosphorIconsLight.calendarDots,
                            size: 19,
                            color: active ? Colors.white : AppColor.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            _buildSearchBar(),
            _TypeSwitch(controller: controller),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: _calendarVisible ? _buildCalendar() : _buildCategoryChips(),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final txDays = <DateTime>{};
    for (final t in controller.homeController.allTransactions) {
      final d = DateTime.tryParse(t['date'] ?? '');
      if (d != null) txDays.add(DateTime(d.year, d.month, d.day));
    }
    return Obx(() => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _WeekStrip(
            txDays: txDays,
            selectedDay: controller.selectedDay.value,
            onDaySelected: controller.filterByDay,
            onClear: controller.clearDayFilter,
          ),
        ));
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Obx(() {
        final hasText = controller.searchQuery.value.isNotEmpty;
        return TextField(
          controller: _searchController,
          onChanged: controller.search,
          style: GoogleFonts.urbanist(color: AppColor.textPrimary, fontSize: 15),
          cursorColor: AppColor.primary,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search by name, category or amount',
            hintStyle: GoogleFonts.urbanist(color: AppColor.textTertiary, fontSize: 14),
            filled: true,
            fillColor: AppColor.surface,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: PhosphorIcon(PhosphorIconsLight.magnifyingGlass,
                  color: AppColor.textSecondary, size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: hasText
                ? IconButton(
                    icon: const PhosphorIcon(PhosphorIconsFill.xCircle,
                        color: AppColor.textTertiary, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      controller.search('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColor.borderStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColor.borderStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryChips() {
    return Obx(() {
      final selectedChip = controller.selectedChip.value;
      final cats = controller.uniqueCategories;
      if (cats.isEmpty) return const SizedBox(height: 4);
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = cats[i];
              final isSelected = selectedChip == cat;
              final color = AppColor.categoryColor(cat);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (isSelected) {
                    controller.selectedChip.value = '';
                    controller.isSelected.value = false;
                    controller.filterTransactions(controller.selectedFilter.value);
                  } else {
                    controller.filterTransactionsByCategory(cat);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColor.primary : AppColor.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: isSelected ? AppColor.primary : AppColor.borderStrong),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        cat,
                        style: GoogleFonts.urbanist(
                          color: isSelected ? Colors.white : AppColor.textPrimary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColor.primary, strokeWidth: 2),
        );
      }
      final transactions = controller.filteredTransactions.toList();
      final sym = controller.homeController.currencySymbol.value;

      if (transactions.isEmpty) {
        final filtering = controller.searchQuery.value.isNotEmpty ||
            controller.selectedChip.value.isNotEmpty ||
            controller.selectedDay.value != null ||
            controller.typeFilter.value.isNotEmpty;
        return _EmptyList(filtering: filtering);
      }

      // Group by day: header (with the day's net) followed by one card of rows
      final groups = <DateTime, List<Map<String, dynamic>>>{};
      for (final tx in transactions) {
        final d = DateTime.tryParse(tx['date'] ?? '');
        if (d == null) continue;
        groups.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(tx);
      }
      final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
      final more = controller.hasMore.value;

      return ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: days.length + 1 + (more ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == 0) return _SummaryCard(controller: controller, sym: sym);
          final idx = i - 1;
          if (idx == days.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: AppColor.primary, strokeWidth: 2),
                ),
              ),
            );
          }
          final day = days[idx];
          return _DayGroup(day: day, txs: groups[day]!, sym: sym);
        },
      );
    });
  }
}

// ── Type switch (All · Expenses · Income) ────────────────────────────────────

class _TypeSwitch extends StatelessWidget {
  final AllTransactionsController controller;
  const _TypeSwitch({required this.controller});

  static const _options = [('', 'All'), ('expense', 'Expenses'), ('income', 'Income')];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Container(
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColor.surfaceVariant,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Obx(() {
            final current = controller.typeFilter.value;
            final idx = _options.indexWhere((o) => o.$1 == current).clamp(0, 2);
            return LayoutBuilder(builder: (_, c) {
              final w = c.maxWidth / _options.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: idx * w,
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.primary.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _options.length; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              controller.setType(_options[i].$1);
                            },
                            child: Center(
                              child: Text(
                                _options[i].$2,
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: i == idx ? FontWeight.w700 : FontWeight.w500,
                                  color: i == idx ? AppColor.textPrimary : AppColor.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            });
          }),
        ),
      );
}

// ── Summary of everything that matches the filters ───────────────────────────

class _SummaryCard extends StatelessWidget {
  final AllTransactionsController controller;
  final String sym;
  const _SummaryCard({required this.controller, required this.sym});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    return Obx(() {
      final count = controller.matchCount.value;
      final spent = controller.matchSpent.value;
      final earned = controller.matchEarned.value;
      final type = controller.typeFilter.value;
      final net = earned - spent;

      Widget stat(String label, String value, Color color, Object icon) => Expanded(
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColor.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: PhosphorIcon(icon, size: 15, color: color, duotoneSecondaryOpacity: 0.3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTypography.caption(AppColor.textSecondary)),
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

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: AppColor.bannerBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$count ${count == 1 ? 'transaction' : 'transactions'}',
                    style: AppTypography.captionSemiBold(AppColor.textSecondary),
                  ),
                  const Spacer(),
                  if (type.isEmpty && count > 0)
                    Text(
                      'Net ${net >= 0 ? '+' : '−'}$sym${fmt.format(net.abs())}',
                      style: AppTypography.captionSemiBold(
                          net >= 0 ? AppColor.income : AppColor.expense),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (type != 'income')
                    stat('Spent', '$sym${fmt.format(spent)}', AppColor.expense,
                        PhosphorIconsDuotone.arrowUpRight),
                  if (type.isEmpty) const SizedBox(width: 10),
                  if (type != 'expense')
                    stat('Earned', '$sym${fmt.format(earned)}', AppColor.income,
                        PhosphorIconsDuotone.arrowDownLeft),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Day group ─────────────────────────────────────────────────────────────────

class _DayGroup extends StatelessWidget {
  final DateTime day;
  final List<Map<String, dynamic>> txs;
  final String sym;
  const _DayGroup({required this.day, required this.txs, required this.sym});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (day.year == now.year) return DateFormat('EEE, d MMM').format(day);
    return DateFormat('EEE, d MMM yyyy').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final net = txs.fold(0.0, (s, t) {
      final a = (t['amount'] as num?)?.toDouble() ?? 0;
      return t['type'] == 'income' ? s + a : s - a;
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Text(
                  _label(),
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColor.heading,
                  ),
                ),
                const Spacer(),
                Text(
                  '${net >= 0 ? '+' : '−'}$sym${fmt.format(net.abs())}',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: net >= 0 ? AppColor.income : AppColor.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.borderStrong),
            ),
            child: Column(
              children: [
                for (var i = 0; i < txs.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColor.border, indent: 64, endIndent: 14),
                  TransactionListItem(
                    key: ValueKey(txs[i]['id'] ?? txs[i]),
                    transaction: [txs[i]],
                    index: 0,
                    categoryList: categoryList,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyList extends StatelessWidget {
  final bool filtering;
  const _EmptyList({required this.filtering});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 60, 40, 120),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColor.primaryExtraSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColor.borderStrong),
              ),
              child: Center(
                child: PhosphorIcon(
                  filtering ? PhosphorIconsDuotone.magnifyingGlass : PhosphorIconsDuotone.receipt,
                  size: 40,
                  color: AppColor.primary,
                  duotoneSecondaryOpacity: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              filtering ? 'Nothing matches' : 'No transactions yet',
              style: AppTypography.heading3(AppColor.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              filtering
                  ? 'Try a different search, category or date.'
                  : 'Log your first expense or income to see it here.',
              textAlign: TextAlign.center,
              style: AppTypography.body(AppColor.textSecondary),
            ),
            if (!filtering) ...[
              const SizedBox(height: 20),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => Get.to(() => const AddTransactionScreen(initialType: 'expense')),
                  icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 15, color: Colors.white),
                  label: const Text('Add a transaction'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

// ── Week Strip Calendar ───────────────────────────────────────────────────────

class _WeekStrip extends StatefulWidget {
  final Set<DateTime> txDays;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onClear;

  const _WeekStrip({
    required this.txDays,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onClear,
  });

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
  static const _initPage = 500;
  late final PageController _pc = PageController(initialPage: _initPage);
  String _monthLabel = '';

  static DateTime get _thisMonday {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  // page _initPage = current week; lower pages are earlier weeks.
  DateTime _weekStart(int page) =>
      _thisMonday.subtract(Duration(days: (_initPage - page) * 7));

  void _updateMonthLabel(int page) {
    final ws = _weekStart(page);
    final we = ws.add(const Duration(days: 6));
    setState(() {
      _monthLabel = ws.month == we.month
          ? DateFormat('MMMM yyyy').format(ws)
          : '${DateFormat('MMM').format(ws)} – ${DateFormat('MMM yyyy').format(we)}';
    });
  }

  @override
  void initState() {
    super.initState();
    _updateMonthLabel(_initPage);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.borderStrong),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(
              children: [
                const PhosphorIcon(PhosphorIconsLight.caretLeft,
                    size: 12, color: AppColor.textTertiary),
                const SizedBox(width: 6),
                Text(
                  _monthLabel,
                  style: GoogleFonts.urbanist(
                    color: AppColor.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (widget.selectedDay != null)
                  GestureDetector(
                    onTap: widget.onClear,
                    child: Text(
                      'Show all',
                      style: AppTypography.captionSemiBold(AppColor.primary),
                    ),
                  )
                else
                  Text('Swipe for earlier weeks',
                      style: AppTypography.caption(AppColor.textTertiary)),
              ],
            ),
          ),
          SizedBox(
            height: 64,
            child: PageView.builder(
              controller: _pc,
              itemCount: _initPage + 1, // no future weeks
              onPageChanged: _updateMonthLabel,
              itemBuilder: (_, page) {
                final ws = _weekStart(page);
                return Row(
                  children: List.generate(7, (i) {
                    final day = ws.add(Duration(days: i));
                    final isToday = day == today;
                    final sel = widget.selectedDay;
                    final isSelected = sel != null &&
                        day.year == sel.year &&
                        day.month == sel.month &&
                        day.day == sel.day;
                    final hasTx = widget.txDays.contains(day);
                    final isFuture = day.isAfter(today);

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isFuture
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                widget.onDaySelected(day);
                              },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(day)[0],
                              style: GoogleFonts.urbanist(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isFuture
                                    ? AppColor.textTertiary.withValues(alpha: 0.4)
                                    : AppColor.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColor.primary
                                    : isToday
                                        ? AppColor.primaryExtraSoft
                                        : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isToday && !isSelected
                                    ? Border.all(color: AppColor.primary, width: 1.2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isFuture
                                        ? AppColor.textTertiary.withValues(alpha: 0.4)
                                        : isSelected
                                            ? Colors.white
                                            : AppColor.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasTx && !isFuture
                                    ? (isSelected ? AppColor.primary : AppColor.warning)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
