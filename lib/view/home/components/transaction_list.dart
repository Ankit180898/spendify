import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/transaction_list_item.dart';

class TransactionsContent extends StatelessWidget {
  int? limit;
  TransactionsContent(this.limit, {super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final monthlyTransactions = controller.groupTransactionsByMonth();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0),
          child: Text(
            'Transactions',
            style: titleText(18, AppColor.secondary),
          ),
        ),
        Obx(
          () => controller.isLoading.value == true
              ? const CircularProgressIndicator()
              : controller.transactions.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: monthlyTransactions.keys.length,
                      itemBuilder: (context, monthIndex) {
                        String month = monthlyTransactions.keys.elementAt(monthIndex);
                        List<Map<String, dynamic>> transactionsForMonth = monthlyTransactions[month]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                              child: Text(
                                month,
                                style: normalText(14, AppColor.secondarySoft)
                              ),
                            ),
                            ListView.separated(
                              padding: const EdgeInsets.all(0),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: transactionsForMonth.length,
                              itemBuilder: (context, transactionIndex) {
                                return TransactionListItem(
                                  transaction: transactionsForMonth,
                                  index: transactionIndex,
                                );
                              },
                              separatorBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Divider(
                                  thickness: 0.5,
                                  color: AppColor.secondaryExtraSoft,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : const Center(
                      child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: Text("No transactions"),
                    )),
        ),
      ],
    );
  }
}
