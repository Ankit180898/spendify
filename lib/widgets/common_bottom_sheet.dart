import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  final _isOthers = false.obs;
  final _customCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.resetForm();
    controller.selectedType.value = 'income';
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  final List<_CategoryItem> _categories = const [
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final handleColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    // Leave at least 20% of screen as tappable barrier above the sheet
    final maxContentHeight = screenHeight * 0.78;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimens.radiusXXXL),
          topRight: Radius.circular(AppDimens.radiusXXXL),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle — always visible, never scrolls away
            GestureDetector(
              onVerticalDragUpdate: (d) {
                if (d.primaryDelta != null && d.primaryDelta! > 8) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: 40,
                height: 4,
                margin:
                    const EdgeInsets.symmetric(vertical: AppDimens.spaceLG),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                ),
              ),
            ),

            // Scrollable content — capped so sheet never fills full screen
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxContentHeight.clamp(200.0, screenHeight * 0.78),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.spaceLG,
                  AppDimens.spaceSM,
                  AppDimens.spaceLG,
                  AppDimens.spaceXXL + keyboardHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SectionLabel('Add Transaction', isDark),
                    const SizedBox(height: AppDimens.spaceXXL),

                    _buildTypeSelector(isDark),
                    const SizedBox(height: AppDimens.spaceXXL),

                    _buildAmountInput(isDark),
                    const SizedBox(height: AppDimens.spaceXXL),

                    _buildCategoryGrid(isDark),
                    const SizedBox(height: AppDimens.spaceXL),

                    _buildDateRow(isDark),
                    const SizedBox(height: AppDimens.spaceMD),

                    _buildDescriptionInput(isDark),
                    const SizedBox(height: AppDimens.spaceXXL),

                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
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
                icon: PhosphorIconsLight.arrowUp,
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
                icon: PhosphorIconsLight.arrowDown,
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
        Obx(() => _isOthers.value
            ? _buildCustomCategoryInput(isDark)
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildCustomCategoryInput(bool isDark) {
    final bg = isDark ? AppColor.darkCard : AppColor.lightBg;
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

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
              color: AppColor.primary.withOpacity(0.10),
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
                hintStyle:
                    AppTypography.bodyLarge(textSecondary.withOpacity(0.6)),
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
    final catColor = AppColor.categoryColor(cat.name);
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final bg = isDark ? AppColor.darkCard : AppColor.lightBg;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

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
                child: PhosphorIcon(
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
              child: const PhosphorIcon(
                PhosphorIconsLight.calendar,
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
            PhosphorIcon(PhosphorIconsLight.caretRight,
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
                  child: const PhosphorIcon(
                    PhosphorIconsLight.pencilSimple,
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
      final btnColor = isExpense ? AppColor.expense : AppColor.income;

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
            PhosphorIcon(
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
