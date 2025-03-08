import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/all_transaction/all_transaction_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/transaction_list_item.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final controller = Get.put(AllTransactionsController());
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_showFab) {
          setState(() {
            _showFab = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_showFab) {
          setState(() {
            _showFab = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.darkBackground,
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        child: Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(
                selected: controller.selectedFilter.value == 'all',
                label: Text('All', style: normalText(14, Colors.white)),
                onSelected: (bool selected) {
                  if (selected) {
                    controller.filterTransactions('all');
                  }
                },
                backgroundColor: AppColor.darkSurface,
                selectedColor: AppColor.primary,
                labelStyle: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: controller.selectedFilter.value == 'weekly',
                label: Text('Weekly', style: normalText(14, Colors.white)),
                onSelected: (bool selected) {
                  if (selected) {
                    controller.filterTransactions('weekly');
                  }
                },
                backgroundColor: AppColor.darkSurface,
                selectedColor: AppColor.primary,
                labelStyle: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: controller.selectedFilter.value == 'monthly',
                label: Text('Monthly', style: normalText(14, Colors.white)),
                onSelected: (bool selected) {
                  if (selected) {
                    controller.filterTransactions('monthly');
                  }
                },
                backgroundColor: AppColor.darkSurface,
                selectedColor: AppColor.primary,
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ],
          ).paddingSymmetric(vertical: 16),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        backgroundColor: AppColor.darkBackground,
        title: Text(
          'Transactions',
          style: titleText(18, Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(
        () => Column(
          children: [
            // Category Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: categoryList.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: controller.selectedChip.value == category.name,
                      label: Text(
                        category.name,
                        style: normalText(14, Colors.white),
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          controller.filterTransactionsByCategory(category.name);
                        } else {
                          controller.selectedChip.value = '';
                          controller.isSelected.value = false;
                          controller.filterTransactions(controller.selectedFilter.value);
                        }
                      },
                      backgroundColor: AppColor.darkSurface,
                      selectedColor: AppColor.primary,
                      labelStyle: const TextStyle(color: Colors.white),
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
                    final monday = now.subtract(Duration(days: now.weekday - 1));
                    final sunday = monday.add(const Duration(days: 6));
                    dateRange = '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d').format(sunday)}';
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

                final transactions =
                    controller.isSelected.value ? controller.filteredTransactions : controller.filteredTransactions;

                if (transactions.isEmpty) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.hourglass_empty,
                        size: 24,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No transactions found',
                        style: normalText(16, Colors.white),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  controller: _scrollController, // Add scroll controller here
                  padding: const EdgeInsets.all(0),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionListItem(
                      transaction: [transaction],
                      index: 0,
                      categoryList: categoryList,
                    );
                  },
                ).paddingSymmetric(horizontal: 16.0);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
