import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/all_transaction/all_transaction_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/transaction_list_item.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final controller = Get.put(AllTransactionsController());
  final ScrollController _scrollController = ScrollController();
  bool _showFilterBar = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final dir = _scrollController.position.userScrollDirection;
      if (dir == ScrollDirection.reverse && _showFilterBar) {
        setState(() => _showFilterBar = false);
      } else if (dir == ScrollDirection.forward && !_showFilterBar) {
        setState(() => _showFilterBar = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: divColor),
        ),
      ),
      body: Column(
        children: [
          _buildCategoryChips(isDark),
          _buildDateLabel(isDark),
          Expanded(child: _buildList(isDark)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        offset: _showFilterBar ? Offset.zero : const Offset(0, 2.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          opacity: _showFilterBar ? 1.0 : 0.0,
          child: _buildPeriodFilterBar(isDark),
        ),
      ),
    );
  }

  Widget _buildPeriodFilterBar(bool isDark) {
    final bg = isDark ? AppColor.darkCard : Colors.white;
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

    return Obx(() {
      final selected = controller.selectedFilter.value;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PeriodPill(label: 'All', isSelected: selected == 'all', isDark: isDark,
                onTap: () => controller.filterTransactions('all')),
            _PeriodPill(label: 'Weekly', isSelected: selected == 'weekly', isDark: isDark,
                onTap: () => controller.filterTransactions('weekly')),
            _PeriodPill(label: 'Monthly', isSelected: selected == 'monthly', isDark: isDark,
                onTap: () => controller.filterTransactions('monthly')),
          ],
        ),
      );
    });
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

  Widget _buildDateLabel(bool isDark) {
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    return Obx(() {
      final now = DateTime.now();
      final filter = controller.selectedFilter.value;
      String label;
      switch (filter) {
        case 'weekly':
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final sunday = monday.add(const Duration(days: 6));
          label = '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d, yyyy').format(sunday)}';
          break;
        case 'monthly':
          label = DateFormat('MMMM yyyy').format(now);
          break;
        default:
          label = 'All transactions';
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
        child: Row(
          children: [
            PhosphorIcon(PhosphorIconsLight.calendar, color: textMuted, size: 12),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: textMuted, fontSize: 12)),
          ],
        ),
      );
    });
  }

  Widget _buildList(bool isDark) {
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
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
              PhosphorIcon(PhosphorIconsLight.receipt, size: 40, color: textMuted.withValues(alpha: 0.3)),
              const SizedBox(height: 10),
              Text('No transactions found', style: TextStyle(color: textMuted, fontSize: 14)),
            ],
          ),
        );
      }
      return ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: transactions.length,
        itemBuilder: (_, i) => TransactionListItem(
          transaction: [transactions[i]],
          index: 0,
          categoryList: categoryList,
        ),
      );
    });
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PeriodPill({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
