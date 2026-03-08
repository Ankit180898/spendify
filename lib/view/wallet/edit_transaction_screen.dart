import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/model/categories_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDIT TRANSACTION SCREEN
// Full-page edit form that mirrors the add-transaction sheet layout.
// ─────────────────────────────────────────────────────────────────────────────
class EditTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final List<CategoriesModel> categoryList;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
    required this.categoryList,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late final TransactionController controller;
  late final RxString _selectedType;

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
  void initState() {
    super.initState();
    controller = Get.find<TransactionController>();
    controller.amountController.text =
        widget.transaction['amount'].toString();
    controller.titleController.text =
        widget.transaction['description'] ?? '';
    controller.selectedCategory.value =
        widget.transaction['category'] ?? '';
    controller.selectedType.value =
        widget.transaction['type'] ?? 'expense';
    controller.selectedDate.value = widget.transaction['date'] ??
        DateTime.now().toIso8601String();
    _selectedType = controller.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : AppColor.lightBg;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left,
              color: textPrimary, size: AppDimens.iconLG),
          onPressed: Get.back,
        ),
        title: Text('Edit Transaction',
            style: AppTypography.heading2(textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: border),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceLG,
          AppDimens.spaceXXL,
          AppDimens.spaceLG,
          AppDimens.spaceHuge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            _buildTypeSelector(isDark),
            const SizedBox(height: AppDimens.spaceXXL),

            // Amount hero input
            _buildAmountInput(isDark),
            const SizedBox(height: AppDimens.spaceXXL),

            // Category heading
            Text('Category', style: AppTypography.heading3(textPrimary)),
            const SizedBox(height: AppDimens.spaceMD),

            // Category grid
            _buildCategoryGrid(isDark),
            const SizedBox(height: AppDimens.spaceXL),

            // Date row
            _buildDateRow(isDark),
            const SizedBox(height: AppDimens.spaceMD),

            // Description input
            _buildDescriptionInput(isDark),
            const SizedBox(height: AppDimens.spaceXXL),

            // Save button
            _buildSaveButton(isDark),
          ],
        ),
      ),
    );
  }

  // ── Type selector ───────────────────────────────────────────────────────────

  Widget _buildTypeSelector(bool isDark) {
    final bg = isDark ? AppColor.darkCard : AppColor.lightBg;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Obx(() {
      final isIncome = _selectedType.value == 'income';
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
                  _selectedType.value = 'income';
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
                  _selectedType.value = 'expense';
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
      final isExpense = _selectedType.value == 'expense';
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
              Text('₹',
                  style: AppTypography.amountDisplay(
                      amountColor.withOpacity(0.6))),
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
    return GridView.builder(
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
                child: Icon(cat.icon,
                    color: catColor, size: AppDimens.iconMD),
              ),
              const SizedBox(height: AppDimens.spaceXS + 2),
              Text(
                cat.name.split(' ').first,
                style: AppTypography.label(
                    isSelected ? catColor : textSecondary),
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
              child: const Icon(Iconsax.calendar_1,
                  color: AppColor.primary, size: AppDimens.iconMD),
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
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: border),
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
            child: const Icon(Iconsax.edit_2,
                color: AppColor.primary, size: AppDimens.iconMD),
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
  }

  // ── Save button ─────────────────────────────────────────────────────────────

  Widget _buildSaveButton(bool isDark) {
    return Obx(() {
      final isLoading = controller.isLoading.isTrue;
      final isExpense = _selectedType.value == 'expense';
      final gradient =
          isExpense ? AppColor.expenseGradient : AppColor.incomeGradient;

      return GestureDetector(
        onTap: isLoading
            ? null
            : () async {
                HapticFeedback.mediumImpact();
                await controller.updateTransaction(
                    widget.transaction['id']);
                Get.back();
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
                  color:
                      (isExpense ? AppColor.expense : AppColor.income)
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
                  : Text('Save Changes',
                      style: AppTypography.button(Colors.white)),
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
      builder: (ctx, child) => Theme(
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
      ),
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
          color: isSelected
              ? selectedColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? selectedColor : textSecondary,
                size: AppDimens.iconMD),
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
