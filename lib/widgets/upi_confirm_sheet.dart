import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
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

  static const _icons = <String, Object>{
    'Food & Drinks': PhosphorIconsDuotone.forkKnife,
    'Groceries': PhosphorIconsDuotone.shoppingCart,
    'Transport': PhosphorIconsDuotone.bus,
    'Car': PhosphorIconsDuotone.car,
    'Shopping': PhosphorIconsDuotone.shoppingBag,
    'Bills & Fees': PhosphorIconsDuotone.lightning,
    'Health': PhosphorIconsDuotone.heartbeat,
    'Entertainment': PhosphorIconsDuotone.filmSlate,
    'Travel': PhosphorIconsDuotone.airplaneTilt,
    'Investments': PhosphorIconsDuotone.trendUp,
    'Education': PhosphorIconsDuotone.graduationCap,
    'Subscriptions': PhosphorIconsDuotone.repeat,
    'Gifts': PhosphorIconsDuotone.gift,
    'Others': PhosphorIconsDuotone.tag,
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_ctrl.pendingCaptures.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
        return const SizedBox.shrink();
      }

      if (_index >= _ctrl.pendingCaptures.length) _index = 0;
      final capture = _ctrl.pendingCaptures[_index];
      final total = _ctrl.pendingCaptures.length;
      final isExpense = capture.type == 'expense';
      final sym = Get.isRegistered<HomeController>()
          ? Get.find<HomeController>().currencySymbol.value
          : '₹';
      final fmt = NumberFormat('#,##0.##', 'en_IN');

      // Detected category first, then the rest
      final cats = [
        ...categoryList.where((c) => c.name == _selectedCategory),
        ...categoryList.where((c) => c.name != _selectedCategory),
      ];

      return Container(
        decoration: const BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
                  decoration: BoxDecoration(
                    color: AppColor.bannerBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PhosphorIcon(PhosphorIconsFill.lightning,
                          size: 13, color: AppColor.warning),
                      const SizedBox(width: 5),
                      Text('Captured from ${capture.source}',
                          style: AppTypography.captionSemiBold(AppColor.primary)),
                    ],
                  ),
                ),
                const Spacer(),
                if (total > 1)
                  Text('${_index + 1} of $total',
                      style: AppTypography.captionSemiBold(AppColor.textTertiary)),
              ],
            ),
            const SizedBox(height: 18),

            // ── Amount ─────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${isExpense ? '−' : '+'}$sym${fmt.format(capture.amount)}',
                      style: GoogleFonts.urbanist(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: isExpense ? AppColor.textPrimary : AppColor.income,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isExpense ? 'Paid to' : 'Received from'} ${capture.merchant}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySemiBold(AppColor.textPrimary),
                  ),
                  Text(_formattedTime(capture.capturedAt),
                      style: AppTypography.caption(AppColor.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Category ───────────────────────────────────────────
            Text('Category',
                style: GoogleFonts.urbanist(
                    fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.heading)),
            const SizedBox(height: 10),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final selected = c.name == _selectedCategory;
                  final color = AppColor.categoryColor(c.name);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = c.name);
                    },
                    child: SizedBox(
                      width: 68,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: selected ? color : color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: PhosphorIcon(
                                _icons[c.name] ?? PhosphorIconsDuotone.tag,
                                size: 22,
                                color: selected ? Colors.white : color,
                                duotoneSecondaryOpacity: 0.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.name.split(' ').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? AppColor.textPrimary : AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // ── Actions ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _saving ? null : _skip,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        foregroundColor: AppColor.textSecondary,
                        side: const BorderSide(color: AppColor.borderStrong),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Skip', style: AppTypography.bodySemiBold(AppColor.textSecondary)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Save ${isExpense ? 'expense' : 'income'}'),
                    ),
                  ),
                ),
              ],
            ),
            if (total > 1)
              Center(
                child: TextButton(
                  onPressed: _skipAll,
                  child: Text('Skip all $total',
                      style: AppTypography.caption(AppColor.textTertiary)),
                ),
              ),
          ],
        ),
      );
    });
  }

  String _formattedTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final time = DateFormat('h:mm a').format(dt);
    if (day == today) return 'Today at $time';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday at $time';
    return '${DateFormat('d MMM').format(dt)} at $time';
  }
}
