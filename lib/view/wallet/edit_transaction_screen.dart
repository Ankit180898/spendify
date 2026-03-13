import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
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
  final _isOthers = false.obs;
  final _customCategoryController = TextEditingController();

  static const List<_CategoryItem> _predefined = [
    _CategoryItem('Investments', PhosphorIconsLight.chartBar),
    _CategoryItem('Health', PhosphorIconsLight.heart),
    _CategoryItem('Bills & Fees', PhosphorIconsLight.receipt),
    _CategoryItem('Food & Drinks', PhosphorIconsLight.coffee),
    _CategoryItem('Car', PhosphorIconsLight.car),
    _CategoryItem('Groceries', PhosphorIconsLight.shoppingCart),
    _CategoryItem('Gifts', PhosphorIconsLight.gift),
    _CategoryItem('Transport', PhosphorIconsLight.bus),
    _CategoryItem('Others', PhosphorIconsLight.squaresFour),
  ];

  List<_CategoryItem> get _categories => _predefined;

  @override
  void initState() {
    super.initState();
    controller = Get.find<TransactionController>();
    controller.amountController.text =
        widget.transaction['amount'].toString();
    controller.titleController.text =
        widget.transaction['description'] ?? '';
    controller.selectedType.value =
        widget.transaction['type'] ?? 'expense';
    controller.selectedDate.value = widget.transaction['date'] ??
        DateTime.now().toIso8601String();
    _selectedType = controller.selectedType;

    // Detect if the saved category is custom (not in predefined list)
    final currentCat = widget.transaction['category'] as String? ?? '';
    final isPredefined =
        _predefined.any((c) => c.name == currentCat || c.name == 'Others');
    if (!isPredefined && currentCat.isNotEmpty) {
      _isOthers.value = true;
      _customCategoryController.text = currentCat;
      controller.selectedCategory.value = currentCat;
    } else {
      controller.selectedCategory.value = currentCat;
    }
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
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
          icon: PhosphorIcon(PhosphorIconsLight.arrowLeft,
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
                icon: PhosphorIconsLight.arrowUp,
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
                icon: PhosphorIconsLight.arrowDown,
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
              Text(Get.find<HomeController>().currencySymbol.value,
                  style: AppTypography.amountDisplay(
                      amountColor.withValues(alpha: 0.6))),
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
                          textPrimary.withValues(alpha: 0.15)),
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
          Divider(height: 1, color: dividerColor),
        ],
      );
    });
  }

  // ── Category grid ───────────────────────────────────────────────────────────

  Widget _buildCategoryGrid(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Obx(() => _isOthers.value
            ? _buildCustomCategoryInput(isDark)
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildCustomCategoryInput(bool isDark) {
    final bg = isDark ? AppColor.darkCard : AppColor.lightBg;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(top: AppDimens.spaceMD),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: AppColor.primary, width: 1.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppDimens.spaceLG),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const PhosphorIcon(PhosphorIconsLight.pencilSimple,
                color: AppColor.primary, size: AppDimens.iconMD),
          ),
          const SizedBox(width: AppDimens.spaceMD),
          Expanded(
            child: TextField(
              controller: _customCategoryController,
              autofocus: true,
              style: AppTypography.bodyLarge(textPrimary),
              cursorColor: AppColor.primary,
              onChanged: (val) => controller.selectedCategory.value = val,
              decoration: InputDecoration(
                hintText: 'Enter custom category…',
                hintStyle: AppTypography.bodyLarge(
                    textSecondary.withValues(alpha: 0.6)),
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

  Widget _buildCategoryCell(_CategoryItem cat, bool isDark) {
    final iconBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final iconFg = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

    return Obx(() {
      final isSelected = cat.name == 'Others'
          ? _isOthers.value
          : (!_isOthers.value &&
              controller.selectedCategory.value == cat.name);
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          if (cat.name == 'Others') {
            _isOthers.value = true;
            controller.selectedCategory.value =
                _customCategoryController.text;
          } else {
            _isOthers.value = false;
            controller.selectedCategory.value = cat.name;
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? AppColor.primary.withValues(alpha: 0.08) : iconBg,
            borderRadius: BorderRadius.circular(AppDimens.radiusLG),
            border: Border.all(
              color: isSelected ? AppColor.primary : border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(cat.icon,
                  color: isSelected ? AppColor.primary : iconFg,
                  size: AppDimens.iconMD),
              const SizedBox(height: AppDimens.spaceXS + 2),
              Text(
                cat.name.split(' ').first,
                style: AppTypography.label(
                    isSelected ? AppColor.primary : textMuted),
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
                color: AppColor.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const PhosphorIcon(PhosphorIconsLight.calendar,
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
            PhosphorIcon(PhosphorIconsLight.arrowRight,
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
              color: AppColor.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const PhosphorIcon(PhosphorIconsLight.pencilSimple,
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
                    textSecondary.withValues(alpha: 0.6)),
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
      final btnColor = isExpense ? AppColor.expense : AppColor.income;

      return GestureDetector(
        onTap: isLoading
            ? null
            : () async {
                HapticFeedback.mediumImpact();
                await controller.updateTransaction(
                    widget.transaction['id'].toString());
              },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isLoading ? 0.6 : 1.0,
          child: Container(
            width: double.infinity,
            height: AppDimens.buttonHeight,
            decoration: BoxDecoration(
              color: btnColor,
              borderRadius: BorderRadius.circular(AppDimens.radiusMD),
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
  final PhosphorIconData icon;
  const _CategoryItem(this.name, this.icon);
}

class _TypePill extends StatelessWidget {
  final String label;
  final PhosphorIconData icon;
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
              ? selectedColor.withValues(alpha: 0.10)
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
            PhosphorIcon(icon,
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
