import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';

class CategoriesGrid extends StatelessWidget {
  const CategoriesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final filteredTransactions = controller.filteredTransactions
          .where((transaction) =>
              DateTime.parse(transaction['date']).year ==
              controller.selectedYear.value)
          .toList();

      if (filteredTransactions.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(50.0),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text("No transactions found for this period",
                    style: mediumTextStyle(16, Colors.white)),
              ],
            ),
          ),
        );
      }

      // Group transactions by category and type
      Map<String, Map<String, double>> categoryTotals = {};

      for (var transaction in filteredTransactions) {
        String category = transaction['category'];
        String type = transaction['type'];
        double amount = transaction['amount'].toDouble();

        categoryTotals[category] ??= {'income': 0.0, 'expense': 0.0};
        categoryTotals[category]![type] =
            (categoryTotals[category]![type] ?? 0.0) + amount;
      }

      if (categoryTotals.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(50.0),
          child: Center(
              child: Text("No transactions found for this period",
                  style: mediumTextStyle(16, Colors.white))),
        );
      }

      // Convert to list and sort by total amount
      var sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => (b.value['expense']! + b.value['income']!)
            .compareTo(a.value['expense']! + a.value['income']!));

      return ListView.builder(
        padding: const EdgeInsets.all(0),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          var entry = sortedCategories[index];
          String category = entry.key;
          double incomeAmount = entry.value['income'] ?? 0.0;
          double expenseAmount = entry.value['expense'] ?? 0.0;
          double totalAmount = incomeAmount + expenseAmount;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColor.darkBackground.withOpacity(0.9),
                  AppColor.darkSurface.withOpacity(0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: titleText(16, Colors.white),
                    ),
                    Text(
                      'Total: ${NumberFormat.currency(locale: 'en_US', symbol: '₹').format(totalAmount)}',
                      style: titleText(16, Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (incomeAmount > 0)
                      Text(
                        'Income: ${NumberFormat.currency(locale: 'en_US', symbol: '₹').format(incomeAmount)}',
                        style: normalText(14, Colors.green),
                      ),
                    if (expenseAmount > 0)
                      Text(
                        'Expense: ${NumberFormat.currency(locale: 'en_US', symbol: '₹').format(expenseAmount)}',
                        style: normalText(14, Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: totalAmount > 0 ? expenseAmount / totalAmount : 0,
                  backgroundColor: Colors.green.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.red.withOpacity(0.7)),
                ),
              ],
            ),
          );
        },
      ).paddingAll(16);
    });
  }
}
