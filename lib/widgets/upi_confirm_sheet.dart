import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/upi_capture_controller/upi_capture_controller.dart';
import 'package:spendify/service/upi_notification_service.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class UpiConfirmSheet extends StatefulWidget {
  const UpiConfirmSheet({super.key});

  @override
  State<UpiConfirmSheet> createState() => _UpiConfirmSheetState();
}

class _UpiConfirmSheetState extends State<UpiConfirmSheet> {
  late final UpiCaptureController _ctrl;
  int _index = 0;
  late String _selectedCategory;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<UpiCaptureController>();
    _resetCategory();
  }

  UpiCapture get _current => _ctrl.pendingCaptures[_index];

  void _resetCategory() {
    if (_ctrl.pendingCaptures.isEmpty) return;
    _selectedCategory = _ctrl.pendingCaptures[_index].category;
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    final merchant = _current.merchant;
    setState(() => _saving = true);
    await _ctrl.saveCapture(_current, _selectedCategory);
    setState(() => _saving = false);

    CustomToast.successToast('Saved', '$merchant logged automatically');

    if (_ctrl.pendingCaptures.isEmpty) {
      Get.back();
    } else {
      if (_index >= _ctrl.pendingCaptures.length) _index = 0;
      setState(_resetCategory);
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    _ctrl.dismissCapture(_current);
    if (_ctrl.pendingCaptures.isEmpty) {
      Get.back();
    } else {
      if (_index >= _ctrl.pendingCaptures.length) _index = 0;
      setState(_resetCategory);
    }
  }

  void _skipAll() {
    _ctrl.dismissAll();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.darkElevated : AppColor.lightSurface;
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightBg;
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Obx(() {
      if (_ctrl.pendingCaptures.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
        return const SizedBox.shrink();
      }

      final capture = _ctrl.pendingCaptures[_index];
      final total = _ctrl.pendingCaptures.length;
      final isExpense = capture.type == 'expense';

      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.primaryExtraSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PhosphorIcon(PhosphorIconsLight.lightning, color: AppColor.primary, size: 12),
                      const SizedBox(width: 4),
                      Text('Auto-captured · ${capture.source}',
                          style: AppTypography.caption(AppColor.primary)),
                    ],
                  ),
                ),
                const Spacer(),
                if (total > 1)
                  Text('$total pending', style: AppTypography.caption(textSecondary)),
              ],
            ),
            const SizedBox(height: 20),

            // Amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isExpense ? '−' : '+',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isExpense ? AppColor.expense : AppColor.income,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '₹${capture.amount % 1 == 0 ? capture.amount.toInt() : capture.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: isExpense ? AppColor.expense : AppColor.income,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(capture.merchant,
                      style: AppTypography.bodySemiBold(textPrimary)),
                  const SizedBox(height: 2),
                  Text(_formattedTime(capture.capturedAt),
                      style: AppTypography.caption(textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category selector
            Text('Category', style: AppTypography.label(textSecondary)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  icon: PhosphorIcon(PhosphorIconsLight.caretDown,
                      color: textSecondary, size: 16),
                  style: AppTypography.body(textPrimary),
                  items: categoryList.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat.name,
                      child: Row(
                        children: [
                          Icon(cat.icon,
                              size: 16,
                              color: AppColor.categoryColor(cat.name)),
                          const SizedBox(width: 8),
                          Text(cat.name,
                              style: AppTypography.body(textPrimary)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _skip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(color: border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Skip',
                        style: AppTypography.button(textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Save as ${isExpense ? "Expense" : "Income"}',
                            style: AppTypography.button(Colors.white),
                          ),
                  ),
                ),
              ],
            ),

            if (total > 1) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _skipAll,
                  child: Text('Skip all $total captures',
                      style: AppTypography.caption(textSecondary)),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _formattedTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return 'Today at $h:$m $period';
  }
}
