// lib/view/transactions/all_transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/transaction_list_item.dart';
import 'package:intl/intl.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColor.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColor.darkBackground,
        title: Text(
          'Transactions',
          style: titleText(18, Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(
        () => Column(
          children: [
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    selected: controller.selectedFilter.value == 'all',
                    label: Text('All', style: normalText(14, Colors.white)),
                    onSelected: (bool selected) {
                      if (selected) {
                        controller.selectedFilter.value = 'all';
                        controller.filterTransactions('all');
                      }
                    },
                    backgroundColor: AppColor.primarySoft,
                    selectedColor: AppColor.primary,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: controller.selectedFilter.value == 'weekly',
                    label: Text('Weekly', style: normalText(14, Colors.white)),
                    onSelected: (bool selected) {
                      if (selected) {
                        controller.selectedFilter.value = 'weekly';
                        controller.filterTransactions('weekly');
                      }
                    },
                    backgroundColor: AppColor.primarySoft,
                    selectedColor: AppColor.primary,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: controller.selectedFilter.value == 'monthly',
                    label: Text('Monthly', style: normalText(14, Colors.white)),
                    onSelected: (bool selected) {
                      if (selected) {
                        controller.selectedFilter.value = 'monthly';
                        controller.filterTransactions('monthly');
                      }
                    },
                    backgroundColor: AppColor.primarySoft,
                    selectedColor: AppColor.primary,
                  ),
                ],
              ),
            ),

            // Category Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: categoryList.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected:
                          controller.selectedChip.value == category.category,
                      label: Text(
                        category.category,
                        style: normalText(14, Colors.white),
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          controller
                              .filterTransactionsByCategory(category.category);
                        } else {
                          controller.selectedChip.value = '';
                          controller.isSelected.value = false;
                          controller.filterTransactions(
                              controller.selectedFilter.value);
                        }
                      },
                      backgroundColor: AppColor.primarySoft,
                      selectedColor: AppColor.primary,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Date Range Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Obx(() {
                String dateRange = '';
                final now = DateTime.now();

                switch (controller.selectedFilter.value) {
                  case 'weekly':
                    final monday =
                        now.subtract(Duration(days: now.weekday - 1));
                    final sunday = monday.add(const Duration(days: 6));
                    dateRange =
                        '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d').format(sunday)}';
                    break;
                  case 'monthly':
                    dateRange = DateFormat('MMMM yyyy').format(now);
                    break;
                  case 'all':
                    dateRange = 'All transactions';
                    break;
                }

                return Text(
                  dateRange,
                  style: normalText(14, AppColor.secondarySoft),
                );
              }),
            ),

            // Transactions List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = controller.isSelected.value
                    ? controller.filteredTransactionsByCategoryList
                    : controller.filteredTransactions;

                if (transactions.isEmpty) {
                  return Center(
                    child: Text(
                      'No transactions found',
                      style: normalText(16, Colors.white),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionListItem(
                      transaction: [transaction],
                      index: 0,
                    );
                  },
                  separatorBuilder: (context, index) => Divider(
                    thickness: 0.2,
                    color: AppColor.secondarySoft.withOpacity(0.6),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
