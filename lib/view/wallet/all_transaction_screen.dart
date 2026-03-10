import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/all_transaction/all_transaction_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/transaction_list_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ALL TRANSACTIONS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
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
    final bg = isDark ? AppColor.darkBg : AppColor.lightBg;
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(isDark, textPrimary),
      body: Column(
        children: [
          // Category filter chips
          _buildCategoryChips(isDark),

          // Date range label
          _buildDateLabel(isDark),

          // Transaction list
          Expanded(child: _buildList(isDark)),
        ],
      ),

      // Time-period filter bar (slides away on scroll)
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

  // ── App bar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark, Color textPrimary) {
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    return AppBar(
      backgroundColor: isDark ? AppColor.darkBg : AppColor.lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: PhosphorIcon(PhosphorIconsLight.arrowLeft,
            color: textPrimary, size: AppDimens.iconLG),
        onPressed: Get.back,
      ),
      title: Text('Transactions', style: AppTypography.heading2(textPrimary)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: border),
      ),
    );
  }

  // ── Period filter bar (floating) ────────────────────────────────────────────

  Widget _buildPeriodFilterBar(bool isDark) {
    final bg = isDark ? AppColor.darkElevated : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Obx(() {
      final selected = controller.selectedFilter.value;
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceXS,
          vertical: AppDimens.spaceXS,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
          border: Border.all(color: border),
          boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PeriodPill(
              label: 'All',
              isSelected: selected == 'all',
              isDark: isDark,
              onTap: () => controller.filterTransactions('all'),
            ),
            _PeriodPill(
              label: 'Weekly',
              isSelected: selected == 'weekly',
              isDark: isDark,
              onTap: () => controller.filterTransactions('weekly'),
            ),
            _PeriodPill(
              label: 'Monthly',
              isSelected: selected == 'monthly',
              isDark: isDark,
              onTap: () => controller.filterTransactions('monthly'),
            ),
          ],
        ),
      );
    });
  }

  // ── Category chips ──────────────────────────────────────────────────────────

  Widget _buildCategoryChips(bool isDark) {
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    return Obx(() {
      final selectedChip = controller.selectedChip.value;
      final cats = controller.uniqueCategories;
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceLG),
          itemCount: cats.length,
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppDimens.spaceXS),
          itemBuilder: (_, i) {
            final cat = cats[i];
            final catColor = AppColor.categoryColor(cat);
            final isSelected = selectedChip == cat;
            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  controller.selectedChip.value = '';
                  controller.isSelected.value = false;
                  controller.filterTransactions(
                      controller.selectedFilter.value);
                } else {
                  controller.filterTransactionsByCategory(cat);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spaceMD,
                  vertical: AppDimens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? catColor.withOpacity(0.14)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusCircle),
                  border: Border.all(
                    color: isSelected ? catColor : border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check_rounded,
                          color: catColor, size: AppDimens.iconXS),
                      const SizedBox(width: AppDimens.spaceXXS + 1),
                    ],
                    Text(
                      cat,
                      style: AppTypography.captionSemiBold(
                          isSelected ? catColor : (isDark
                              ? AppColor.textSecondary
                              : AppColor.lightTextSecondary)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ── Date range label ────────────────────────────────────────────────────────

  Widget _buildDateLabel(bool isDark) {
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    return Obx(() {
      final now = DateTime.now();
      final filter = controller.selectedFilter.value;
      String label;
      switch (filter) {
        case 'weekly':
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final sunday = monday.add(const Duration(days: 6));
          label =
              '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d, yyyy').format(sunday)}';
          break;
        case 'monthly':
          label = DateFormat('MMMM yyyy').format(now);
          break;
        default:
          label = 'All transactions';
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.spaceLG, AppDimens.spaceXS,
            AppDimens.spaceLG, AppDimens.spaceSM),
        child: Row(
          children: [
            PhosphorIcon(PhosphorIconsLight.calendar,
                color: textSecondary, size: AppDimens.iconXS),
            const SizedBox(width: AppDimens.spaceXXS + 2),
            Text(label, style: AppTypography.caption(textSecondary)),
          ],
        ),
      );
    });
  }

  // ── Transaction list ────────────────────────────────────────────────────────

  Widget _buildList(bool isDark) {
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColor.primary),
        );
      }
      final transactions = controller.filteredTransactions;
      if (transactions.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const PhosphorIcon(PhosphorIconsLight.receipt,
                    color: AppColor.primary, size: AppDimens.iconXXL),
              ),
              const SizedBox(height: AppDimens.spaceMD),
              Text('No transactions found',
                  style: AppTypography.bodyLarge(textSecondary)),
            ],
          ),
        );
      }
      return ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceLG,
          AppDimens.spaceXS,
          AppDimens.spaceLG,
          // extra bottom padding so last item isn't behind filter bar
          AppDimens.spaceHuge + AppDimens.spaceXXL,
        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// PERIOD PILL
// ─────────────────────────────────────────────────────────────────────────────
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
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceXXL,
          vertical: AppDimens.spaceSM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
        ),
        child: Text(
          label,
          style: AppTypography.captionSemiBold(
              isSelected ? Colors.white : textSecondary),
        ),
      ),
    );
  }
}
