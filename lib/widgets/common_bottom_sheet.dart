import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';

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
    final bg = isDark ? AppColor.darkSurface : Colors.white;
    final handleColor = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (screenHeight * 0.78).clamp(200.0, screenHeight * 0.78),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + keyboardHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Text('Add Transaction',
                          style: TextStyle(
                            color: isDark ? AppColor.textPrimary : const Color(0xFF09090B),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    const SizedBox(height: 20),

                    _buildTypeSelector(isDark),
                    const SizedBox(height: 24),

                    _buildAmountInput(isDark),
                    const SizedBox(height: 20),

                    // Category label
                    Text('Category',
                        style: TextStyle(
                          color: isDark ? AppColor.textSecondary : const Color(0xFF71717A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 10),

                    _buildCategoryGrid(isDark),
                    const SizedBox(height: 16),

                    _buildDateRow(isDark),
                    const SizedBox(height: 10),

                    _buildDescriptionInput(isDark),
                    const SizedBox(height: 24),

                    _buildSubmitButton(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Type selector ────────────────────────────────────────────────────────────

  Widget _buildTypeSelector(bool isDark) {
    final segBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);

    return Obx(() {
      final isIncome = _transactionType.value == Transactions.income;
      return Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: segBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(child: _TypePill(
              label: 'Income',
              isSelected: isIncome,
              selectedColor: AppColor.income,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                _transactionType.value = Transactions.income;
                controller.selectedType.value = 'income';
              },
            )),
            Expanded(child: _TypePill(
              label: 'Expense',
              isSelected: !isIncome,
              selectedColor: AppColor.expense,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                _transactionType.value = Transactions.expense;
                controller.selectedType.value = 'expense';
              },
            )),
          ],
        ),
      );
    });
  }

  // ── Amount input ─────────────────────────────────────────────────────────────

  Widget _buildAmountInput(bool isDark) {
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);

    return Obx(() {
      final isExpense = _transactionType.value == Transactions.expense;
      final amountColor = isExpense ? AppColor.expense : AppColor.income;
      return Column(
        children: [
          Text(
            isExpense ? 'Expense amount' : 'Income amount',
            style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(Get.find<HomeController>().currencySymbol.value,
                  style: TextStyle(
                    color: amountColor.withValues(alpha: 0.5),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  )),
              const SizedBox(width: 4),
              Flexible(
                child: IntrinsicWidth(
                  child: TextField(
                    controller: controller.amountController,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    cursorColor: AppColor.primary,
                    cursorWidth: 2.0,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: textPrimary.withValues(alpha: 0.15),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
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
          const SizedBox(height: 12),
          Divider(height: 1, color: divColor),
        ],
      );
    });
  }

  // ── Category grid ─────────────────────────────────────────────────────────────

  Widget _buildCategoryGrid(bool isDark) {
    final preferred = Get.find<HomeController>().selectedCategories;
    final sorted = [
      ..._categories.where((c) => preferred.contains(c.name)),
      ..._categories.where((c) => !preferred.contains(c.name)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (preferred.isNotEmpty) ...[
          Text('Your categories',
              style: TextStyle(
                color: isDark ? AppColor.textTertiary : const Color(0xFF9CA3AF),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 8),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemCount: sorted.length,
          itemBuilder: (_, i) => _buildCategoryCell(sorted[i], isDark,
              isPreferred: preferred.contains(sorted[i].name)),
        ),
        Obx(() => _isOthers.value
            ? _buildCustomCategoryInput(isDark)
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildCustomCategoryInput(bool isDark) {
    final bg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.primary, width: 1.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const PhosphorIcon(PhosphorIconsLight.pencilSimple, color: AppColor.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _customCategoryController,
              autofocus: true,
              style: TextStyle(color: textPrimary, fontSize: 14),
              cursorColor: AppColor.primary,
              onChanged: (val) => controller.selectedCategory.value = val,
              decoration: InputDecoration(
                hintText: 'Custom category name…',
                hintStyle: TextStyle(color: textMuted, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _buildCategoryCell(_CategoryItem cat, bool isDark, {bool isPreferred = false}) {
    final iconBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final iconFg = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

    return Obx(() {
      final isSelected = cat.name == 'Others'
          ? _isOthers.value
          : (!_isOthers.value && controller.selectedCategory.value == cat.name);

      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          if (cat.name == 'Others') {
            _isOthers.value = true;
            controller.selectedCategory.value = _customCategoryController.text;
          } else {
            _isOthers.value = false;
            controller.selectedCategory.value = cat.name;
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? AppColor.primary.withValues(alpha: 0.08) : iconBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColor.primary : (isPreferred ? AppColor.primary.withValues(alpha: 0.35) : border),
              width: isSelected ? 1.5 : (isPreferred ? 1.0 : 1.0),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                cat.icon,
                color: isSelected ? AppColor.primary : iconFg,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                cat.name.split(' ').first,
                style: TextStyle(
                  color: isSelected ? AppColor.primary : textMuted,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

  // ── Date row ──────────────────────────────────────────────────────────────────

  Widget _buildDateRow(bool isDark) {
    final bg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            PhosphorIcon(PhosphorIconsLight.calendar, color: textMuted, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(() => Text(
                    DateFormat('EEE, MMM d yyyy')
                        .format(DateTime.parse(controller.selectedDate.value)),
                    style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  )),
            ),
            PhosphorIcon(PhosphorIconsLight.caretRight, color: textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Description input ─────────────────────────────────────────────────────────

  Widget _buildDescriptionInput(bool isDark) {
    final bg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller.titleController,
        style: TextStyle(color: textPrimary, fontSize: 14),
        cursorColor: AppColor.primary,
        decoration: InputDecoration(
          hintText: 'Note (optional)',
          hintStyle: TextStyle(color: textMuted, fontSize: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          filled: false,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: PhosphorIcon(PhosphorIconsLight.pencilSimple, color: textMuted, size: 16),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────────

  Widget _buildSubmitButton(bool isDark) {
    return Obx(() {
      final isLoading = controller.isLoading.isTrue;
      final isExpense = _transactionType.value == Transactions.expense;
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
            height: 50,
            decoration: BoxDecoration(
              color: btnColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isExpense ? 'Add Expense' : 'Add Income',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  // ── Date picker ───────────────────────────────────────────────────────────────

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
              )
            : ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColor.primary,
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
  final bool isSelected;
  final Color selectedColor;
  final bool isDark;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
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
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColor.darkElevated : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedColor : textMuted,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

enum Transactions { income, expense }
