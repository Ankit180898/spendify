import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/view/wallet/transaction_details_screen.dart';

import '../../config/app_color.dart';
import '../../controller/home_controller/home_controller.dart';

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
    final category = trans['category'];
    final amount = trans['amount'].toString();
    final isExpense = trans['type'] == 'expense';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2530),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Show transaction details or edit
              // controller.showTransactionDetails(trans);
              Get.to(
                () => TransactionDetailsScreen(
                  transaction: trans,
                  categoryList: categoryList,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Category Icon
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(category, isExpense).withOpacity(0.2),
                          _getCategoryColor(category, isExpense).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      controller.getCategoryIcon(category, categoryList),
                      color: _getCategoryColor(category, isExpense),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trans['description'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.formatDateTime(trans['date'].toString()),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExpense ? AppColor.error.withOpacity(0.2) : AppColor.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isExpense ? "-₹$amount" : "+₹$amount",
                      style: TextStyle(
                        color: isExpense ? AppColor.error : AppColor.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category, bool isExpense) {
    // Use a fixed color if it's income
    if (!isExpense) {
      return AppColor.success;
    }

    // For expenses, map categories to colors
    final Map<String, Color> categoryColors = {
      'food': Colors.orange,
      'shopping': Colors.purple,
      'transport': Colors.blue,
      'entertainment': Colors.pink,
      'bills': Colors.red,
      'health': Colors.green,
      'education': Colors.teal,
      'other': AppColor.primary,
    };

    return categoryColors[category.toLowerCase()] ?? AppColor.primary;
  }
}
