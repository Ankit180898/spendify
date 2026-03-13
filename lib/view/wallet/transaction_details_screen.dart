import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/view/wallet/add_transaction_screen.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final List<CategoriesModel> categoryList;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
    required this.categoryList,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final txCtrl = Get.find<TransactionController>();
    final isExpense = transaction['type'] == 'expense';
    final category = transaction['category'] as String? ?? '';
    final amount = transaction['amount'].toString();
    final date = DateTime.parse(transaction['date']);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final description = transaction['description']?.toString() ?? '';

    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);
    final amountColor = isExpense ? AppColor.expense : AppColor.income;
    final iconBg = isDark ? AppColor.darkElevated : const Color(0xFFF4F4F8);
    final iconFg = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

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
        title: Text('Details', style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: PhosphorIcon(PhosphorIconsLight.pencilSimple, color: textMuted, size: 20),
            onPressed: () async {
              final result = await Get.to(() => AddTransactionScreen(
                    initialType: transaction['type'] ?? 'expense',
                    transaction: transaction,
                  ));
              if (result == true) {
                await ctrl.getTransactions();
                Get.back();
              }
            },
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsLight.trash, color: AppColor.expense, size: 20),
            onPressed: () => _confirmDelete(context, txCtrl, isDark, textPrimary, textMuted),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount hero — centered
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                    child: Icon(ctrl.getCategoryIcon(category, categoryList), color: iconFg, size: 24),
                  ),
                  const SizedBox(height: 16),
                  if (description.isNotEmpty)
                    Text(description,
                        style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    '${isExpense ? '-' : '+'}${ctrl.currencySymbol.value}$amount',
                    style: TextStyle(color: amountColor, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMMM d, yyyy').format(date), style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            Divider(height: 1, color: divColor),
            _Row(label: 'Category', value: category.isNotEmpty ? category : '—', primary: textPrimary, muted: textMuted, div: divColor),
            _Row(label: 'Type', value: isExpense ? 'Expense' : 'Income', primary: amountColor, muted: textMuted, div: divColor),
            _Row(label: 'Date', value: DateFormat('EEE, d MMM yyyy').format(date), primary: textPrimary, muted: textMuted, div: divColor, last: true),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, TransactionController txCtrl, bool isDark, Color primary, Color muted) async {
    final ok = await Get.dialog<bool>(AlertDialog(
      backgroundColor: isDark ? AppColor.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete?', style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w700)),
      content: Text('This will be permanently deleted.', style: TextStyle(color: muted, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: Text('Cancel', style: TextStyle(color: muted))),
        TextButton(onPressed: () => Get.back(result: true), child: const Text('Delete', style: TextStyle(color: AppColor.expense, fontWeight: FontWeight.w600))),
      ],
    ));
    if (ok == true) {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: AppColor.primary)),
        barrierDismissible: false,
      );
      await txCtrl.deleteTransaction(transaction['id'].toString());
      Get.back(); // dismiss loader
      Get.back(); // pop details screen
    }
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color primary;
  final Color muted;
  final Color div;
  final bool last;
  const _Row({required this.label, required this.value, required this.primary, required this.muted, required this.div, this.last = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(children: [
              Text(label, style: TextStyle(color: muted, fontSize: 14)),
              const Spacer(),
              Text(value, style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (!last) Divider(height: 1, color: div),
        ],
      );
}
