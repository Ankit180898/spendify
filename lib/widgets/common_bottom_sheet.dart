import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ADD TRANSACTION BOTTOM SHEET
// Inspired by Copilot Money & Wallet by BudgetBakers:
//  • Hero amount input centred at the top
//  • Income / Expense pill selector with semantic colors
//  • Circular category icons with per-category accent colors
//  • Theme-aware (dark navy / crisp white)
// ─────────────────────────────────────────────────────────────────────────────
class CommonBottomSheet extends StatefulWidget {
  const CommonBottomSheet({super.key});

  @override
  _CommonBottomSheetState createState() => _CommonBottomSheetState();
}

class _CommonBottomSheetState extends State<CommonBottomSheet> {
  final controller = Get.find<TransactionController>();
  final _transactionType = Transactions.income.obs;

  @override
  void initState() {
    super.initState();
    // Keep controller in sync with the UI default (income)
    controller.selectedType.value = 'income';
  }

  final List<_CategoryItem> _categories = const [
    _CategoryItem('Investments', Iconsax.chart_2),
    _CategoryItem('Health', Iconsax.heart),
    _CategoryItem('Bills & Fees', Iconsax.receipt_2),
    _CategoryItem('Food & Drinks', Iconsax.coffee),
    _CategoryItem('Car', Iconsax.car),
    _CategoryItem('Groceries', Iconsax.shop),
    _CategoryItem('Gifts', Iconsax.gift),
    _CategoryItem('Transport', Iconsax.bus),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final handleColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimens.radiusXXXL),
          topRight: Radius.circular(AppDimens.radiusXXXL),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.spaceLG,
            AppDimens.spaceSM,
            AppDimens.spaceLG,
            AppDimens.spaceXXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimens.spaceXXL),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusCircle),
                ),
              ),

              // Title
              _SectionLabel('Add Transaction', isDark),
              const SizedBox(height: AppDimens.spaceXXL),

              // Type selector
              _buildTypeSelector(isDark),
              const SizedBox(height: AppDimens.spaceXXL),

              // Amount hero input
              _buildAmountInput(isDark),
              const SizedBox(height: AppDimens.spaceXXL),

              // Category grid
              _buildCategoryGrid(isDark),
              const SizedBox(height: AppDimens.spaceXL),

              // Date row
              _buildDateRow(isDark),
              const SizedBox(height: AppDimens.spaceMD),

              // Description input
              _buildDescriptionInput(isDark),
              const SizedBox(height: AppDimens.spaceXXL),

              // Submit
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Type selector ───────────────────────────────────────────────────────────

  Widget _buildTypeSelector(bool isDark) {
    final bg = isDark ? AppColor.darkCard : AppColor.lightBg;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Obx(() {
      final isIncome = _transactionType.value == Transactions.income;
      return Container(
        padding: const EdgeInsets.all(AppDimens.spaceXXS + 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TypePill(
                label: 'Income',
                icon: Iconsax.arrow_up_1,
                isSelected: isIncome,
                selectedColor: AppColor.income,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _transactionType.value = Transactions.income;
                  controller.selectedType.value = 'income';
                },
              ),
            ),
            Expanded(
              child: _TypePill(
                label: 'Expense',
                icon: Iconsax.arrow_down_1,
                isSelected: !isIncome,
                selectedColor: AppColor.expense,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _transactionType.value = Transactions.expense;
                  controller.selectedType.value = 'expense';
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Amount input ────────────────────────────────────────────────────────────

  Widget _buildAmountInput(bool isDark) {
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final dividerColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Obx(() {
      final isExpense = _transactionType.value == Transactions.expense;
      final amountColor = isExpense ? AppColor.expense : AppColor.income;
      return Column(
        children: [
          Text(
            isExpense ? 'EXPENSE AMOUNT' : 'INCOME AMOUNT',
            style: AppTypography.label(textSecondary),
          ),
          const SizedBox(height: AppDimens.spaceLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₹',
                style: AppTypography.amountDisplay(
                    amountColor.withOpacity(0.6)),
              ),
              const SizedBox(width: AppDimens.spaceXS),
              Flexible(
                child: IntrinsicWidth(
                  child: TextField(
                    controller: controller.amountController,
                    style: AppTypography.amountDisplay(textPrimary),
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    cursorColor: AppColor.primary,
                    cursorWidth: 2.0,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: AppTypography.amountDisplay(
                          textPrimary.withOpacity(0.18)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isCollapsed: true,
                      filled: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceMD),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  dividerColor.withOpacity(0),
                  dividerColor,
                  dividerColor.withOpacity(0),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  // ── Category grid ───────────────────────────────────────────────────────────

  Widget _buildCategoryGrid(bool isDark) {
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Category', isDark),
        const SizedBox(height: AppDimens.spaceMD),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: AppDimens.spaceMD,
            mainAxisSpacing: AppDimens.spaceMD,
            childAspectRatio: 0.78,
          ),
          itemCount: _categories.length,
          itemBuilder: (_, i) => _buildCategoryCell(_categories[i], isDark),
        ),
      ],
    );
  }

  Widget _buildCategoryCell(_CategoryItem cat, bool isDark) {
    final catColor = AppColor.categoryColor(cat.name);
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final bg = isDark ? AppColor.darkCard : AppColor.lightBg;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Obx(() {
      final isSelected = controller.selectedCategory.value == cat.name;
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          controller.selectedCategory.value = cat.name;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? catColor.withOpacity(0.12) : bg,
            borderRadius: BorderRadius.circular(AppDimens.radiusLG),
            border: Border.all(
              color: isSelected ? catColor : border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? catColor.withOpacity(0.20)
                      : catColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cat.icon,
                  color: catColor,
                  size: AppDimens.iconMD,
                ),
              ),
              const SizedBox(height: AppDimens.spaceXS + 2),
              Text(
                cat.name.split(' ').first, // show first word only
                style: AppTypography.label(
                  isSelected ? catColor : textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Date row ────────────────────────────────────────────────────────────────

  Widget _buildDateRow(bool isDark) {
    final bg = isDark ? AppColor.darkCard : AppColor.lightBg;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceLG,
          vertical: AppDimens.spaceMD,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.calendar_1,
                color: AppColor.primary,
                size: AppDimens.iconMD,
              ),
            ),
            const SizedBox(width: AppDimens.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction Date',
                      style: AppTypography.caption(textSecondary)),
                  const SizedBox(height: 2),
                  Obx(() => Text(
                        DateFormat('EEE, MMM d yyyy').format(
                            DateTime.parse(controller.selectedDate.value)),
                        style: AppTypography.bodySemiBold(textPrimary),
                      )),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3,
                color: textSecondary, size: AppDimens.iconSM),
          ],
        ),
      ),
    );
  }

  // ── Description input ───────────────────────────────────────────────────────

  Widget _buildDescriptionInput(bool isDark) {
    final bg = isDark ? AppColor.darkCard : AppColor.lightBg;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final focusBorder =
        isDark ? AppColor.darkBorderFocus : AppColor.lightBorderFocus;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Focus(
      child: Builder(
        builder: (ctx) {
          final hasFocus = Focus.of(ctx).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppDimens.radiusLG),
              border: Border.all(
                  color: hasFocus ? AppColor.primary : border,
                  width: hasFocus ? 1.5 : 1.0),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppDimens.spaceLG),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.edit_2,
                    color: AppColor.primary,
                    size: AppDimens.iconMD,
                  ),
                ),
                const SizedBox(width: AppDimens.spaceMD),
                Expanded(
                  child: TextField(
                    controller: controller.titleController,
                    style: AppTypography.bodyLarge(textPrimary),
                    cursorColor: AppColor.primary,
                    decoration: InputDecoration(
                      hintText: 'Transaction name or note…',
                      hintStyle: AppTypography.bodyLarge(
                          textSecondary.withOpacity(0.6)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: AppDimens.spaceMD),
                      filled: false,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceLG),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Submit button ───────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return Obx(() {
      final isLoading = controller.isLoading.isTrue;
      final isExpense =
          _transactionType.value == Transactions.expense;
      final gradient =
          isExpense ? AppColor.expenseGradient : AppColor.incomeGradient;

      return GestureDetector(
        onTap: isLoading
            ? null
            : () {
                HapticFeedback.mediumImpact();
                controller.addResource();
              },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isLoading ? 0.6 : 1.0,
          child: Container(
            width: double.infinity,
            height: AppDimens.buttonHeight,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: (isExpense ? AppColor.expense : AppColor.income)
                      .withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isExpense ? 'Add Expense' : 'Add Income',
                      style: AppTypography.button(Colors.white),
                    ),
            ),
          ),
        ),
      );
    });
  }

  // ── Date picker ─────────────────────────────────────────────────────────────

  Future<void> _selectDate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(controller.selectedDate.value),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColor.primary,
                    surface: AppColor.darkElevated,
                    onSurface: AppColor.textPrimary,
                  ),
                  dialogTheme: const DialogThemeData(
                      backgroundColor: AppColor.darkSurface),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColor.primary,
                    surface: AppColor.lightSurface,
                    onSurface: AppColor.lightTextPrimary,
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.selectedDate.value = picked.toIso8601String();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryItem {
  final String name;
  final IconData icon;
  const _CategoryItem(this.name, this.icon);
}

class _TypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final bool isDark;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
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
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.spaceMD,
          horizontal: AppDimens.spaceXS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : textSecondary,
              size: AppDimens.iconMD,
            ),
            const SizedBox(width: AppDimens.spaceXS),
            Text(
              label,
              style: AppTypography.bodySemiBold(
                  isSelected ? selectedColor : textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: AppTypography.heading3(textPrimary)),
    );
  }
}

enum Transactions { income, expense }
