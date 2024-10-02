import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/widgets/categories_grid.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value:  const SystemUiOverlayStyle(
        statusBarColor: Colors.white, // Set status bar color
        statusBarIconBrightness: Brightness.light, // Icon color
    ),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                                WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.white;
                                }
                                return AppColor.primarySoft;
                              },
                            ),
                            enableFeedback: true,
                            side: WidgetStateProperty.all<BorderSide>(
                                const BorderSide(color: Colors.white)),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Spending Details',
                  style: titleText(18, AppColor.secondary),
                ),
              ),
              CategoriesGrid()
            ],
          ),
        ),
      ),
    ),
    );
  }
}
