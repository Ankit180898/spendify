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
              DateTime.parse(transaction['date']).year == controller.selectedYear.value)
          .toList();

      if (filteredTransactions.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(50.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  "No transactions found for this period",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
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
        categoryTotals[category]![type] = (categoryTotals[category]![type] ?? 0.0) + amount;
      }

      if (categoryTotals.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(50.0),
          child: Center(
            child: Text(
              "No spending details available",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        );
      }

      // Convert to list and sort by total amount
      var sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => (b.value['expense']! + b.value['income']!)
            .compareTo(a.value['expense']! + a.value['income']!));

      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView.builder(
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: titleText(16, AppColor.secondary),
                      ),
                      Text(
                        'Total: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(totalAmount)}',
                        style: titleText(16, AppColor.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (incomeAmount > 0) 
                        Text(
                          'Income: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(incomeAmount)}',
                          style: normalText(14, Colors.green),
                        ),
                      if (expenseAmount > 0)
                        Text(
                          'Expense: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(expenseAmount)}',
                          style: normalText(14, Colors.red),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: totalAmount > 0 ? expenseAmount / totalAmount : 0,
                    backgroundColor: Colors.green.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red.withOpacity(0.7)),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
