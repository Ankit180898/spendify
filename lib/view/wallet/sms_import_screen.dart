import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/sms_controller/sms_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/services/sms_parser_service.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final _smsCtrl = Get.put(SmsController());
  final _txCtrl = Get.find<TransactionController>();
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _smsCtrl.scanSms());
  }

  Future<void> _importSelected() async {
    final selected = _smsCtrl.detectedTransactions
        .where((t) => t.isSelected)
        .toList();
    if (selected.isEmpty) { return; }

    setState(() => _importing = true);
    int successCount = 0;

    for (final tx in selected) {
      try {
        // Temporarily fill the transaction controller fields
        _txCtrl.amountController.text = tx.amount.toString();
        _txCtrl.titleController.text = tx.merchant;
        _txCtrl.selectedCategory.value = tx.category;
        _txCtrl.selectedType.value = tx.type;
        _txCtrl.selectedDate.value = tx.date.toIso8601String();
        await _txCtrl.addResource(silent: true);
        successCount++;
      } catch (_) {}
    }

    setState(() => _importing = false);
    _txCtrl.resetForm();

    Get.back();
    Get.find<HomeController>().fetchTotalBalanceData();

    Get.snackbar(
      'Imported',
      '$successCount transaction${successCount == 1 ? '' : 's'} added successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.income,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF9F9F9);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

    if (!Platform.isAndroid) {
      return _NotAvailableScreen(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: PhosphorIcon(PhosphorIconsLight.arrowLeft,
                          color: textPrimary, size: 20),
                      onPressed: Get.back,
                    ),
                    Expanded(
                      child: Text(
                        'SMS Transactions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Obx(() {
                      final hasAny = _smsCtrl.detectedTransactions.isNotEmpty;
                      if (!hasAny) { return const SizedBox(width: 48); }
                      final allSelected = _smsCtrl.detectedTransactions
                          .every((t) => t.isSelected);
                      return TextButton(
                        onPressed: allSelected
                            ? _smsCtrl.deselectAll
                            : _smsCtrl.selectAll,
                        child: Text(
                          allSelected ? 'None' : 'All',
                          style: const TextStyle(
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Obx(() {
                  final count = _smsCtrl.detectedTransactions.length;
                  return Text(
                    count > 0
                        ? 'Found $count transactions in the last 30 days. Select the ones to import.'
                        : 'Scanning your SMS inbox for bank and payment messages…',
                    style: TextStyle(color: textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  );
                }),
              ),

              // Content
              Expanded(
                child: Obx(() {
                  if (_smsCtrl.isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColor.primary,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 16),
                          Text('Reading SMS…',
                              style: TextStyle(color: textMuted, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  if (_smsCtrl.errorMessage.isNotEmpty &&
                      _smsCtrl.detectedTransactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PhosphorIcon(
                              _smsCtrl.hasPermission.value
                                  ? PhosphorIconsLight.chatCircleDots
                                  : PhosphorIconsLight.lock,
                              color: textMuted,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _smsCtrl.errorMessage.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textMuted, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: _smsCtrl.scanSms,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColor.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Try Again',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _smsCtrl.detectedTransactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final tx = _smsCtrl.detectedTransactions[i];
                      return _SmsTransactionCard(
                        tx: tx,
                        isDark: isDark,
                        cardBg: cardBg,
                        border: border,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _smsCtrl.toggleSelection(i);
                        },
                        onCategoryChange: (newCat) {
                          _smsCtrl.detectedTransactions[i].category != newCat;
                          // Update in place
                          final updated = SmsTransaction(
                            rawMessage: tx.rawMessage,
                            amount: tx.amount,
                            type: tx.type,
                            merchant: tx.merchant,
                            category: newCat,
                            date: tx.date,
                            isSelected: tx.isSelected,
                          );
                          _smsCtrl.detectedTransactions[i] = updated;
                        },
                      );
                    },
                  );
                }),
              ),

              // Import button
              Obx(() {
                final count = _smsCtrl.selectedCount;
                if (_smsCtrl.detectedTransactions.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: GestureDetector(
                    onTap: (count == 0 || _importing) ? null : _importSelected,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: (count == 0 || _importing) ? 0.4 : 1.0,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: _importing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  count == 0
                                      ? 'Select transactions to import'
                                      : 'Import $count transaction${count == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual SMS transaction card

class _SmsTransactionCard extends StatelessWidget {
  final SmsTransaction tx;
  final bool isDark;
  final Color cardBg;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onTap;
  final ValueChanged<String> onCategoryChange;

  const _SmsTransactionCard({
    required this.tx,
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
    required this.onCategoryChange,
  });

  static const _allCategories = [
    'Food & Drinks', 'Groceries', 'Transport', 'Bills & Fees', 'Health',
    'Car', 'Shopping', 'Entertainment', 'Investments', 'Education',
    'Travel', 'Gifts', 'Subscriptions', 'Others',
  ];

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == 'expense';
    final accentColor = isExpense ? AppColor.expense : AppColor.income;
    final fmt = DateFormat('d MMM');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tx.isSelected
              ? accentColor.withValues(alpha: 0.06)
              : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: tx.isSelected ? accentColor.withValues(alpha: 0.4) : border,
            width: tx.isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: tx.isSelected
                    ? accentColor
                    : (isDark ? AppColor.darkElevated : const Color(0xFFE4E4E7)),
                shape: BoxShape.circle,
              ),
              child: tx.isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tx.merchant,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isExpense ? '-' : '+'}₹${tx.amount.toStringAsFixed(tx.amount.truncateToDouble() == tx.amount ? 0 : 2)}',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Category picker
                      GestureDetector(
                        onTap: () => _pickCategory(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColor.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tx.category,
                            style: const TextStyle(
                              color: AppColor.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        fmt.format(tx.date),
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickCategory(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColor.darkElevated : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ..._allCategories.map((cat) => ListTile(
                title: Text(cat,
                    style: TextStyle(
                        color: isDark
                            ? AppColor.textPrimary
                            : const Color(0xFF09090B),
                        fontSize: 14)),
                trailing: cat == tx.category
                    ? const Icon(Icons.check, color: AppColor.primary, size: 18)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onCategoryChange(cat);
                },
                dense: true,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS / not-available placeholder

class _NotAvailableScreen extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;

  const _NotAvailableScreen({
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? AppColor.darkBg : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: PhosphorIcon(PhosphorIconsLight.arrowLeft,
                        color: textPrimary, size: 20),
                    onPressed: Get.back,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(PhosphorIconsLight.prohibit,
                          color: textMuted, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'SMS scanning is not available on iOS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: textMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Apple restricts access to the SMS inbox. Use the voice input or manual entry instead.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
