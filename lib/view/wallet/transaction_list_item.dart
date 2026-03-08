import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/view/wallet/transaction_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TRANSACTION LIST ITEM
// Layout inspired by Copilot / Wallet: circular category icon,
// bold amount right-aligned, coral for expense / mint for income.
// ─────────────────────────────────────────────────────────────────────────────
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
    final controller = Get.find<HomeController>();
    final trans = transaction[index];
    final category = trans['category'] as String? ?? '';
    final amount = trans['amount'];
    final isExpense = trans['type'] == 'expense';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColor.darkCard : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textSecondary =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final catColor = AppColor.categoryColor(category);
    final amountColor = isExpense ? AppColor.expense : AppColor.income;
    final amountPrefix = isExpense ? '-' : '+';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.spaceSM),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          splashColor: AppColor.primary.withOpacity(0.06),
          onTap: () => Get.to(
            () => TransactionDetailsScreen(
              transaction: trans,
              categoryList: categoryList,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusLG),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spaceLG,
              vertical: AppDimens.spaceMD,
            ),
            child: Row(
              children: [
                // Circular category icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller.getCategoryIcon(category, categoryList),
                    color: catColor,
                    size: AppDimens.iconMD,
                  ),
                ),

                const SizedBox(width: AppDimens.spaceMD),

                // Description + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trans['description']?.toString() ?? '',
                        style: AppTypography.bodyLarge(textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.spaceXXS),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.spaceXS + 2,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.10),
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusXS),
                            ),
                            child: Text(
                              category,
                              style: AppTypography.label(catColor),
                            ),
                          ),
                          const SizedBox(width: AppDimens.spaceXS),
                          Text(
                            '· ${controller.formatDateTime(trans['date'].toString())}',
                            style: AppTypography.caption(textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppDimens.spaceSM),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountPrefix₹$amount',
                      style: AppTypography.bodySemiBoldTabular(amountColor),
                    ),
                    const SizedBox(height: AppDimens.spaceXXS),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: amountColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
