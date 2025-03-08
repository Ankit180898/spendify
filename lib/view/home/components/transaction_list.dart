import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/all_transaction_screen.dart';
import 'package:spendify/view/wallet/transaction_list_item.dart';

class TransactionsContent extends StatelessWidget {
  final int limit;

  const TransactionsContent(this.limit, {super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 22.0, right: 22.0, top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: titleText(18, Colors.white),
              ),
              TextButton.icon(
                onPressed: () => Get.to(() => const AllTransactionsScreen()),
                icon: Icon(Icons.arrow_forward, size: 16, color: AppColor.primary),
                label: Text(
                  'View All',
                  style: normalText(14, AppColor.primary),
                ),
              ),
            ],
          ),
        ),
        Obx(
          () {
            if (controller.isLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (controller.transactions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No transactions yet",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Add your first transaction action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Add your first transaction"),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Use the grouped transactions directly
            final monthlyTransactions = controller.groupedTransactions;

            return ListView.builder(
              padding: const EdgeInsets.all(0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: monthlyTransactions.keys.length,
              itemBuilder: (context, monthIndex) {
                String month = monthlyTransactions.keys.elementAt(monthIndex);
                List<Map<String, dynamic>> transactionsForMonth = monthlyTransactions[month] ?? [];

                // Apply limit to transactions for each month
                if (limit > 0 && transactionsForMonth.length > limit) {
                  transactionsForMonth = transactionsForMonth.take(limit).toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          month,
                          style: normalText(14, AppColor.primary),
                        ),
                      ),
                    ),
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactionsForMonth.length,
                      itemBuilder: (context, transactionIndex) {
                        return TransactionListItem(
                          key: ValueKey(transactionsForMonth[transactionIndex]),
                          transaction: transactionsForMonth,
                          index: transactionIndex,
                          categoryList: categoryList,
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
