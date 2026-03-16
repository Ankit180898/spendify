import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/all_transaction/all_transaction_controller.dart';
import 'package:spendify/utils/utils.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIconsLight.arrowLeft, color: textPrimary, size: 20),
          onPressed: Get.back,
        ),
        title: Text('Transactions',
            style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          Obx(() {
            final hasDay = controller.selectedDay.value != null;
            return IconButton(
              onPressed: () {
                setState(() => _calendarVisible = !_calendarVisible);
                if (!_calendarVisible) controller.clearDayFilter();
              },
              icon: PhosphorIcon(
                _calendarVisible ? PhosphorIconsLight.calendarX : PhosphorIconsLight.calendarDots,
                color: hasDay ? AppColor.primary : textPrimary,
                size: 20,
              ),
            );
          }),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: divColor),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          if (_calendarVisible) _buildCalendar(isDark),
          if (!_calendarVisible) _buildCategoryChips(isDark),
          Expanded(child: _buildList(isDark)),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    final txDays = <DateTime>{};
    for (final t in controller.homeController.allTransactions) {
      final d = DateTime.tryParse(t['date'] ?? '');
      if (d != null) txDays.add(DateTime(d.year, d.month, d.day));
    }
    return Obx(() => _WeekStrip(
      txDays: txDays,
      selectedDay: controller.selectedDay.value,
      onDaySelected: controller.filterByDay,
      onClear: controller.clearDayFilter,
      isDark: isDark,
    ));
  }

  Widget _buildSearchBar(bool isDark) {
    final inputBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Obx(() {
        final hasText = controller.searchQuery.value.isNotEmpty;
        return TextField(
          controller: _searchController,
          onChanged: controller.search,
          style: TextStyle(color: textPrimary, fontSize: 14),
          cursorColor: AppColor.primary,
          decoration: InputDecoration(
            hintText: 'Search transactions…',
            hintStyle: TextStyle(color: textMuted, fontSize: 14),
            filled: true,
            fillColor: inputBg,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: PhosphorIcon(PhosphorIconsLight.magnifyingGlass,
                  color: textMuted, size: 17),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: hasText
                ? IconButton(
                    icon: PhosphorIcon(PhosphorIconsLight.xCircle,
                        color: textMuted, size: 17),
                    onPressed: () {
                      _searchController.clear();
                      controller.search('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final chipBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);

    return Obx(() {
      final selectedChip = controller.selectedChip.value;
      final cats = controller.uniqueCategories;
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = cats[i];
              final isSelected = selectedChip == cat;
              return GestureDetector(
                onTap: () {
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColor.primary : chipBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textMuted,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildList(bool isDark) {
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final textDim = isDark ? AppColor.textTertiary : const Color(0xFFA1A1AA);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColor.primary, strokeWidth: 2),
        );
      }
      final transactions = controller.filteredTransactions;
      if (transactions.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(PhosphorIconsLight.receipt,
                  size: 40, color: textMuted.withValues(alpha: 0.3)),
              const SizedBox(height: 10),
              Text('No transactions found',
                  style: TextStyle(color: textMuted, fontSize: 14)),
            ],
          ),
        );
      }

      // Build grouped list: month headers + transaction rows
      final items = <_ListItem>[];
      String? lastMonthKey;
      for (final tx in transactions) {
        final date = DateTime.parse(tx['date']);
        final monthKey = DateFormat('MMMM yyyy').format(date);
        if (monthKey != lastMonthKey) {
          items.add(_ListItem.header(monthKey));
          lastMonthKey = monthKey;
        }
        items.add(_ListItem.tx(tx));
      }

      final more = controller.hasMore.value;
      final totalCount = items.length + (more ? 1 : 0);

      return ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: totalCount,
        itemBuilder: (_, i) {
          // Footer loader
          if (i == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: AppColor.primary, strokeWidth: 2),
                ),
              ),
            );
          }
          final item = items[i];
          if (item.isHeader) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                item.header!,
                style: TextStyle(
                  color: textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            );
          }
          final showDivider = i > 0 && !items[i - 1].isHeader;
          return Column(
            children: [
              if (showDivider)
                Divider(height: 1, thickness: 0.5, color: divColor, indent: 72),
              TransactionListItem(
                transaction: [item.tx!],
                index: 0,
                categoryList: categoryList,
              ),
            ],
          );
        },
      );
    });
  }
}

// ── Week Strip Calendar ───────────────────────────────────────────────────────

class _WeekStrip extends StatefulWidget {
  final Set<DateTime> txDays;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onClear;
  final bool isDark;

  const _WeekStrip({
    required this.txDays,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onClear,
    required this.isDark,
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

  // page _initPage = current week, page _initPage-1 = last week, etc.
  // Higher page = more recent. itemCount = _initPage+1 caps at current week.
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
    final isDark = widget.isDark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      color: bg,
      child: Column(
        children: [
          // Month label + clear button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
            child: Row(
              children: [
                Text(_monthLabel,
                    style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                if (widget.selectedDay != null)
                  GestureDetector(
                    onTap: widget.onClear,
                    child: const Text('Clear',
                        style: TextStyle(
                            color: AppColor.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
          // Week strip — swipe left = newer, swipe right = older
          SizedBox(
            height: 68,
            child: PageView.builder(
              controller: _pc,
              itemCount: _initPage + 1, // caps at current week, no future pages
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
                        onTap: isFuture ? null : () => widget.onDaySelected(day),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Day abbreviation
                            Text(
                              DateFormat('E').format(day)[0],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isFuture
                                    ? textMuted.withValues(alpha: 0.25)
                                    : textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Date circle
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColor.primary
                                    : isToday
                                        ? AppColor.primary.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isFuture
                                        ? textMuted.withValues(alpha: 0.25)
                                        : isSelected
                                            ? Colors.white
                                            : isToday
                                                ? AppColor.primary
                                                : textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Transaction dot
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasTx && !isFuture
                                    ? (isSelected
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : AppColor.primary)
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
          // Selected day label
          if (widget.selectedDay != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: Row(
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(widget.selectedDay!),
                    style: const TextStyle(
                        color: AppColor.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Divider(height: 1, color: divColor),
        ],
      ),
    );
  }
}

class _ListItem {
  final String? header;
  final Map<String, dynamic>? tx;
  bool get isHeader => header != null;

  const _ListItem.header(this.header) : tx = null;
  const _ListItem.tx(this.tx) : header = null;
}

