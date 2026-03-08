import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/view/wallet/edit_transaction_screen.dart';

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
    final controller = Get.find<HomeController>();
    final transactionController = Get.find<TransactionController>();
    final isExpense = transaction['type'] == 'expense';
    final category = transaction['category'] as String? ?? '';
    final amount = transaction['amount'].toString();
    final date = DateTime.parse(transaction['date']);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColor.darkBg : AppColor.lightBg;
    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final borderColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final catColor = AppColor.categoryColor(category);
    final amountColor = isExpense ? AppColor.expense : AppColor.income;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Transaction Details',
          style: AppTypography.heading2(textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: AppDimens.iconMD),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: textSecondary, size: AppDimens.iconMD),
            onPressed: () async {
              final result = await Get.to(
                () => EditTransactionScreen(
                  transaction: transaction,
                  categoryList: categoryList,
                ),
              );
              if (result == true) await controller.getTransactions();
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: AppColor.expense, size: AppDimens.iconMD),
            onPressed: () => _confirmDelete(
                context, transactionController, isDark, textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimens.spaceXXXL,
                horizontal: AppDimens.spaceXXL,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                    ),
                    child: Icon(
                      controller.getCategoryIcon(category, categoryList),
                      color: catColor,
                      size: AppDimens.iconHero,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceLG),
                  Text(
                    transaction['description']?.toString() ?? '',
                    style: AppTypography.heading2(textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.spaceSM),
                  Text(
                    isExpense ? '-₹$amount' : '+₹$amount',
                    style: AppTypography.amountDisplay(amountColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.spaceLG),

            // Details list
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppDimens.radiusXXL),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: 'Category',
                    value: category,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    showBorder: true,
                  ),
                  _buildDetailRow(
                    label: 'Type',
                    value: isExpense ? 'Expense' : 'Income',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    showBorder: true,
                    valueColor: amountColor,
                  ),
                  _buildDetailRow(
                    label: 'Date',
                    value: DateFormat('MMMM d, yyyy').format(date),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    showBorder: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required bool showBorder,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceXXL,
        vertical: AppDimens.spaceLG,
      ),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: borderColor, width: 1))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body(textSecondary)),
          Text(
            value,
            style: AppTypography.bodySemiBoldTabular(valueColor ?? textPrimary),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionController transactionController,
    bool isDark,
    Color textPrimary,
  ) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: isDark ? AppColor.darkCard : AppColor.lightSurface,
        title: Text(
          'Delete Transaction',
          style: AppTypography.heading2(textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this transaction?',
          style: AppTypography.body(
              isDark ? AppColor.textSecondary : AppColor.lightTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel',
                style: AppTypography.body(
                    isDark ? AppColor.textSecondary : AppColor.lightTextSecondary)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete',
                style: AppTypography.bodySemiBold(AppColor.expense)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await transactionController
          .deleteTransaction(transaction['id'].toString());
      Get.back();
    }
  }
}
