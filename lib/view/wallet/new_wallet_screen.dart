import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/transaction_list_item.dart';
import 'package:spendify/widgets/bottom_navigation.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum Filtered { weekly, monthly }

class NewWalletScreen extends StatelessWidget {
  const NewWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final controller2 = Get.find<TransactionController>();
    var selectedFilter = 'income'.obs;

    var transactions = Filtered.weekly.obs;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: hideBottomAppBarController,
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Text(
                  "Transactions",
                  style: titleText(24, AppColor.secondary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: AppColor.primaryGradient,
                      borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 16.0),
                        child: SegmentedButton<Filtered>(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.white;
                                }
                                return AppColor.primarySoft;
                              },
                            ),
                            enableFeedback: true,
                            side: MaterialStateProperty.all<BorderSide>(
                                const BorderSide(color: Colors.white)),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                            ),
                          ),
                          showSelectedIcon: true,
                          selectedIcon: Icon(
                            Icons.check,
                            color: AppColor.secondary,
                          ),
                          segments: const <ButtonSegment<Filtered>>[
                            ButtonSegment<Filtered>(
                              value: Filtered.weekly,
                              label: Text('Weekly'),
                            ),
                            ButtonSegment<Filtered>(
                              value: Filtered.monthly,
                              label: Text('Monthly'),
                            ),
                          ],
                          selected: <Filtered>{transactions.value},
                          onSelectionChanged: (Set<Filtered> newSelection) {
                            transactions.value = newSelection.first;
                            controller.selectedFilter.value =
                                newSelection.first == Filtered.weekly
                                    ? 'weekly'
                                    : 'monthly';
                            controller.filterTransactions(
                                controller.selectedFilter.value);
                          },
                        ),
                      ),
                      verticalSpace(16),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SfCartesianChart(
                              primaryXAxis: CategoryAxis(
                                labelStyle: normalText(14, Colors.white),
                                majorGridLines: const MajorGridLines(width: 0),
                              ),
                              primaryYAxis: NumericAxis(
                                  labelStyle: normalText(14, Colors.white),
                                  majorGridLines:
                                      const MajorGridLines(width: 0)),
                              series: <CartesianSeries>[
                                ColumnSeries<Map<String, dynamic>, String>(
                                  color: AppColor.primarySoft,
                                  enableTooltip: true,
                                  dataSource: controller.incomeTransactions,
                                  xValueMapper: (datum, _) => controller
                                              .selectedFilter.value ==
                                          'weekly'
                                      ? DateFormat('EEE')
                                          .format(DateTime.parse(datum['date']))
                                      : DateFormat('MMM').format(
                                          DateTime.parse(datum['date'])),
                                  yValueMapper: (datum, _) => datum['amount'],
                                ),
                                ColumnSeries<Map<String, dynamic>, String>(
                                  color: AppColor.primary,
                                  dataSource: controller.expenseTransactions,
                                  xValueMapper: (datum, _) => controller
                                              .selectedFilter.value ==
                                          'weekly'
                                      ? DateFormat('EEE')
                                          .format(DateTime.parse(datum['date']))
                                      : DateFormat('MMM').format(
                                          DateTime.parse(datum['date'])),
                                  yValueMapper: (datum, _) => datum['amount'],
                                )
                              ])),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: displayHeight(context) * 0.02,
                                  width: displayHeight(context) * 0.02,
                                  color: AppColor.primarySoft,
                                ),
                                horizontalSpace(5),
                                Text(
                                  "Income",
                                  style: normalText(8, AppColor.secondary),
                                )
                              ],
                            ),
                            horizontalSpace(8),
                            Row(
                              children: [
                                Container(
                                  height: displayHeight(context) * 0.02,
                                  width: displayHeight(context) * 0.02,
                                  color: AppColor.primary,
                                ),
                                horizontalSpace(5),
                                Text(
                                  "Expense",
                                  style: normalText(8, AppColor.secondary),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      verticalSpace(16),
                    ],
                  ),
                ),
              ),
              verticalSpace(16),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    Text(
                      'All Transactions',
                      style: titleText(18, AppColor.secondary),
                    ),
                    const Spacer(),
                    IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.filter_list,
                          color: AppColor.secondary,
                        ))
                  ],
                ),
              ),
              ListView.builder(
                padding: const EdgeInsets.all(0),
                shrinkWrap: true,
                reverse: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.transactions.length,
                itemBuilder: (context, index) {
                  var i = controller.transactions[index];
                  var category = i['category'];
                  return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                      child: TransactionListItem(
                        transaction: controller.transactions,
                        index: index,
                      ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// SfCartesianChart(
//                         plotAreaBorderWidth: 0,
//                         primaryXAxis: const CategoryAxis(
//                             majorGridLines: MajorGridLines(width: 0)),
//                         primaryYAxis: NumericAxis(
//                           axisLine: AxisLine(width: 0),
//                           title: AxisTitle(
//                               text: 'Amount',
//                               textStyle:
//                                   mediumTextStyle(16, AppColor.secondary)),
//                         ),
//                         series: <CartesianSeries>[
//                           ColumnSeries<Map<String, dynamic>, String>(
//                             borderRadius: BorderRadius.only(
//                                 topRight: Radius.circular(20),
//                                 topLeft: Radius.circular(20)),
//                             color: AppColor.primarySoft,
//                             enableTooltip: true,
//                             dataSource:
//                                 controller.selectedFilter.value == 'expense'
//                                     ? controller.expenseTransactions
//                                     : controller.incomeTransactions,
//                             xValueMapper: (datum, _) => DateFormat('MMM')
//                                 .format(DateTime.parse(datum['date'])),
//                             yValueMapper: (datum, _) => datum['amount'],
//                             name: 'Expense',
//                           ),
//                         ],
//                       ),