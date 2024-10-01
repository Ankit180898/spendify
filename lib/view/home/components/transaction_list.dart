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
                  ? controller.selectedChip.value.isEmpty
                      ? ListView.separated(
                          reverse: true,
                          padding: const EdgeInsets.all(0),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.transactions.length,
                          itemBuilder: (context, index) {
                            var i = controller.transactions[index];
                            var category = i['category'];
                            return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8.0, top: 8.0),
                                child: TransactionListItem(
                                  transaction: controller.transactions,
                                  index: index,
                                ));
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Divider(
                                thickness: 0.5,
                                color: AppColor.secondaryExtraSoft,
                              ),
                            );
                          },
                        )
                      : ListView.separated(
                          reverse: true,
                          padding: const EdgeInsets.all(0),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller
                              .filteredTransactionsByCategoryList.length,
                          itemBuilder: (context, index) {
                            var i = controller
                                .filteredTransactionsByCategoryList[index];
                            var category = i['category'];
                            return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8.0, top: 8.0),
                                child: TransactionListItem(
                                  transaction: controller
                                      .filteredTransactionsByCategoryList,
                                  index: index,
                                ));
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Divider(
                                thickness: 0.5,
                                color: AppColor.secondaryExtraSoft,
                              ),
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
