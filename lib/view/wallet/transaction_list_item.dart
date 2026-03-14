import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/view/wallet/transaction_details_screen.dart';

class TransactionListItem extends StatelessWidget {
  final List<Map<String, dynamic>> transaction;
  final int index;
  final List<CategoriesModel> categoryList;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.index,
    required this.categoryList,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final tx = transaction[index];
    final category = tx['category'] as String? ?? '';
    final isExpense = tx['type'] == 'expense';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF18181B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final amountColor = isExpense ? AppColor.expense : AppColor.income;
    final catColor = isExpense
        ? AppColor.categoryColor(category)
        : AppColor.income;

    return InkWell(
      onTap: () => Get.to(() => TransactionDetailsScreen(transaction: tx, categoryList: categoryList)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(ctrl.getCategoryIcon(category, categoryList), color: catColor, size: 17),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['description']?.toString().isNotEmpty == true ? tx['description'].toString() : category.isNotEmpty ? category : 'Transaction',
                    style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.isNotEmpty ? '$category · ${ctrl.formatDateTime(tx['date'].toString())}' : ctrl.formatDateTime(tx['date'].toString()),
                    style: TextStyle(color: textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${isExpense ? '-' : '+'}${ctrl.currencySymbol.value}${tx['amount']}',
              style: TextStyle(
                color: amountColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
