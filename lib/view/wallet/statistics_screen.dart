import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/widgets/categories_grid.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/cupertino.dart';

enum Filtered { weekly, monthly }

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  void _showYearPicker(BuildContext context, HomeController controller) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 200,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: AppColor.darkCard,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      'Cancel',
                      style: normalText(16, Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: Text(
                      'Confirm',
                      style: normalText(16, Colors.white),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller
                          .filterTransactions(controller.selectedFilter.value);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: years.indexOf(controller.selectedYear.value),
                  ),
                  onSelectedItemChanged: (int selectedItem) {
                    controller.selectedYear.value = years[selectedItem];
                    controller
                        .filterTransactions(controller.selectedFilter.value);
                  },
                  children: years
                      .map((year) => Center(
                              child: Text(
                            year.toString(),
                            style: mediumTextStyle(16, Colors.white),
                          )))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor:
              AppColor.darkBackground, // Make status bar transparent
          systemNavigationBarColor:
              AppColor.darkBackground, // Bottom nav bar color
          statusBarIconBrightness: Brightness.light, // White status bar icons
          systemNavigationBarIconBrightness: Brightness.light, // Icon color
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColor.darkBackground,
            // gradient: AppColor.darkGradient, // Your gradient background
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                "Statistics",
                style: titleText(24, Colors.white),
              ),
              centerTitle: false,
              actions: [
                InkWell(
                  splashColor: Colors.transparent,
                  onTap: () => _showYearPicker(context, controller),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColor.darkCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(
                          () => Text(
                            controller.selectedYear.value.toString(),
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColor.secondaryExtraSoft),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ).paddingAll(8),
                  ).paddingSymmetric(horizontal: 8),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                              gradient: AppColor.darkGradientAlt,
                              borderRadius: BorderRadius.circular(24)),
                          child: Column(
                            children: [
                              // Add the filter buttons
                              // Row(
                              //   children: [
                              //     Expanded(
                              //       child: InkWell(
                              //         onTap: () =>
                              //             controller.filterTransactions('weekly'),
                              //         child: Container(
                              //           padding:
                              //               const EdgeInsets.symmetric(vertical: 8),
                              //           decoration: BoxDecoration(
                              //             color: controller.selectedFilter.value ==
                              //                     'weekly'
                              //                 ? AppColor.secondaryExtraSoft
                              //                 : Colors.transparent,
                              //             borderRadius: BorderRadius.circular(8),
                              //           ),
                              //           child: Center(
                              //             child: Text(
                              //               'Weekly',
                              //               style: TextStyle(
                              //                 color:
                              //                     controller.selectedFilter.value ==
                              //                             'weekly'
                              //                         ? Colors.white
                              //                         : Colors.white.withOpacity(0.5),
                              //                 fontWeight: FontWeight.bold,
                              //               ),
                              //             ),
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //     const SizedBox(width: 8),
                              //     Expanded(
                              //       child: InkWell(
                              //         onTap: () =>
                              //             controller.filterTransactions('monthly'),
                              //         child: Container(
                              //           padding:
                              //               const EdgeInsets.symmetric(vertical: 8),
                              //           decoration: BoxDecoration(
                              //             color: controller.selectedFilter.value ==
                              //                     'monthly'
                              //                 ? AppColor.secondaryExtraSoft
                              //                 : Colors.transparent,
                              //             borderRadius: BorderRadius.circular(8),
                              //           ),
                              //           child: Center(
                              //             child: Text(
                              //               'Monthly',
                              //               style: TextStyle(
                              //                 color:
                              //                     controller.selectedFilter.value ==
                              //                             'monthly'
                              //                         ? Colors.white
                              //                         : Colors.white.withOpacity(0.5),
                              //                 fontWeight: FontWeight.bold,
                              //               ),
                              //             ),
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 24.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        controller.selectedFilter.value =
                                            'weekly';
                                        controller.filterTransactions(
                                            controller.selectedFilter.value);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0, horizontal: 24.0),
                                        decoration: BoxDecoration(
                                          color: controller
                                                      .selectedFilter.value ==
                                                  'weekly'
                                              ? Colors.white // Selected color
                                              : Colors
                                                  .transparent, // Deselected color
                                          borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8.0),
                                              bottomLeft: Radius.circular(8)),
                                          border: Border.all(
                                            color: controller
                                                        .selectedFilter.value ==
                                                    'weekly'
                                                ? Colors
                                                    .transparent // No border when selected
                                                : Colors
                                                    .white, // Border color when not selected
                                          ),
                                        ),
                                        child: Text(
                                          'Weekly',
                                          style: normalText(
                                              14,
                                              controller.selectedFilter.value ==
                                                      'weekly'
                                                  ? Colors.black
                                                  : Colors.white),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        controller.selectedFilter.value =
                                            'monthly';
                                        controller.filterTransactions(
                                            controller.selectedFilter.value);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0, horizontal: 24.0),
                                        decoration: BoxDecoration(
                                          color: controller
                                                      .selectedFilter.value ==
                                                  'monthly'
                                              ? Colors.white // Selected color
                                              : Colors
                                                  .transparent, // Deselected color
                                          borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(8.0),
                                              bottomRight: Radius.circular(8)),
                                          border: Border.all(
                                            color: controller
                                                        .selectedFilter.value ==
                                                    'monthly'
                                                ? Colors
                                                    .transparent // No border when selected
                                                : Colors
                                                    .white, // Border color when not selected
                                          ),
                                        ),
                                        child: Text(
                                          'Monthly',
                                          style: normalText(
                                              14,
                                              controller.selectedFilter.value ==
                                                      'monthly'
                                                  ? Colors.black
                                                  : Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: SfCartesianChart(
                                  tooltipBehavior: TooltipBehavior(),
                                  primaryXAxis: CategoryAxis(
                                    labelStyle: normalText(14, Colors.white),
                                    majorGridLines:
                                        const MajorGridLines(width: 0),
                                  ),
                                  primaryYAxis: NumericAxis(
                                    labelStyle: normalText(14, Colors.white),
                                    majorGridLines:
                                        const MajorGridLines(width: 0),
                                  ),
                                  series: <CartesianSeries>[
                                    // Income Series
                                    ColumnSeries<Map<String, dynamic>, String>(
                                      color: AppColor.secondaryExtraSoft,
                                      enableTooltip: true,
                                      dataSource: controller
                                          .filteredTransactions
                                          .where((transaction) =>
                                              transaction['type'] == 'income' &&
                                              DateTime.parse(
                                                          transaction['date'])
                                                      .year ==
                                                  controller.selectedYear.value)
                                          .toList(),
                                      xValueMapper: (datum, _) {
                                        final date =
                                            DateTime.parse(datum['date']);
                                        return controller
                                                    .selectedFilter.value ==
                                                'weekly'
                                            ? DateFormat('EEE').format(date)
                                            : DateFormat('MMM').format(date);
                                      },
                                      yValueMapper: (datum, _) =>
                                          datum['amount'],
                                    ),
                                    // Expense Series
                                    ColumnSeries<Map<String, dynamic>, String>(
                                      color: AppColor.secondarySoft,
                                      enableTooltip: true,
                                      dataSource: controller
                                          .filteredTransactions
                                          .where((transaction) =>
                                              transaction['type'] ==
                                                  'expense' &&
                                              DateTime.parse(
                                                          transaction['date'])
                                                      .year ==
                                                  controller.selectedYear.value)
                                          .toList(),
                                      xValueMapper: (datum, _) {
                                        final date =
                                            DateTime.parse(datum['date']);
                                        return controller
                                                    .selectedFilter.value ==
                                                'weekly'
                                            ? DateFormat('EEE').format(date)
                                            : DateFormat('MMM').format(date);
                                      },
                                      yValueMapper: (datum, _) =>
                                          datum['amount'],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text('Spending Details',
                            style: mediumTextStyle(18, Colors.white)),
                      ),
                      const CategoriesGrid(),
                    ],
                  )),
            ),
          ),
        ));
  }
}

class ChartData {
  final String date;
  double income;
  double expense;

  ChartData(this.date, this.income, this.expense);
}

// Create a separate widget for the chart
class TransactionChart extends StatelessWidget {
  const TransactionChart({super.key});

  List<ChartData> _processChartData(
      List<Map<String, dynamic>> transactions, String filterType) {
    final Map<String, ChartData> chartData = {};

    for (var transaction in transactions) {
      try {
        final date = DateTime.parse(transaction['date']);
        final key = filterType == 'weekly'
            ? DateFormat('d MMM').format(date)
            : DateFormat('MMM').format(date);

        final amount = (transaction['amount'] ?? 0.0).toDouble();
        final isIncome = transaction['type'] == 'income';

        // Create new ChartData if it doesn't exist
        if (!chartData.containsKey(key)) {
          chartData[key] = ChartData(key, 0, 0);
        }

        // Update the values
        if (isIncome) {
          chartData[key]!.income += amount;
        } else {
          chartData[key]!.expense += amount;
        }
      } catch (e) {
        print('Error processing transaction: $e');
        continue;
      }
    }

    // Sort the data by date
    final sortedData = chartData.values.toList();
    return sortedData;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final chartData = _processChartData(
          controller.filteredTransactions, controller.selectedFilter.value);

      if (chartData.isEmpty) {
        return const Center(
          child: Text(
            'No transactions yet',
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      return SfCartesianChart(
        margin: const EdgeInsets.all(0),
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(
          labelStyle: TextStyle(color: Colors.white, fontSize: 12),
          majorGridLines: MajorGridLines(width: 0),
          labelRotation: 45,
        ),
        primaryYAxis: const NumericAxis(
          labelStyle: TextStyle(color: Colors.white, fontSize: 12),
          majorGridLines: MajorGridLines(
            width: 1,
            color: Colors.white24,
          ),
          axisLine: AxisLine(width: 0),
        ),
        series: <CartesianSeries>[
          ColumnSeries<ChartData, String>(
            name: 'Income',
            color: AppColor.success.withOpacity(0.7),
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.date,
            yValueMapper: (ChartData data, _) => data.income,
            borderRadius: BorderRadius.circular(4),
          ),
          ColumnSeries<ChartData, String>(
            name: 'Expense',
            color: AppColor.error.withOpacity(0.7),
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.date,
            yValueMapper: (ChartData data, _) => data.expense,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}
