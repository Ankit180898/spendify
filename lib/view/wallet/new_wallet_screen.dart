import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/utils/image_constants.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/widgets/bottom_navigation.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum Filtered { weekly, monthly }

class NewWalletScreen extends StatelessWidget {
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
              Container(
                decoration: BoxDecoration(
                    gradient: AppColor.primaryGradient,
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 32.0, horizontal: 24.0),
                      child: Text(
                        "Transactions",
                        style: titleText(24, AppColor.secondaryExtraSoft),
                      ),
                    ),
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
                              BorderSide(color: Colors.white)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
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
                                majorGridLines: const MajorGridLines(width: 0)),
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
                                    : DateFormat('MMM')
                                        .format(DateTime.parse(datum['date'])),
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
                                    : DateFormat('MMM')
                                        .format(DateTime.parse(datum['date'])),
                                yValueMapper: (datum, _) => datum['amount'],
                              )
                            ])),
                    verticalSpace(16),
                  ],
                ),
              ),
              verticalSpace(16),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Text(
                  'All Transactions',
                  style: titleText(18, AppColor.secondary),
                ),
              ),
              ListView.builder(
                padding: const EdgeInsets.all(0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.filteredTransactions.length,
                itemBuilder: (context, index) {
                  var i = controller.filteredTransactions[index];
                  var category = i['category'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColor.secondaryExtraSoft,
                          child: getCategoryImage(category, categoryList)),
                      title: Text(
                        '${i['description']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: Text(
                        _formatDateTime('${i['date']}'),
                        style: TextStyle(
                            fontSize: 14, color: AppColor.secondarySoft),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          i['type'] == 'expense'
                              ? ImageConstants(colors: AppColor.warning).expense
                              : ImageConstants(colors: AppColor.success).income,
                          Text("${i['amount']}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

// Function to parse and format date time string
  String _formatDateTime(String dateTimeString) {
    final dateTime =
        DateTime.parse(dateTimeString); // Parse the date time string
    return DateFormat("MMMM d, y").format(dateTime); // Format the date and time
  }

  // Function to get the category image based on the category name
  Widget getCategoryImage(String category, List<CategoriesModel> categoryList) {
    var matchingCategory = categoryList.firstWhere(
      (element) => element.category == category,
      orElse: () => CategoriesModel(category: '', image: ''),
    );

    if (matchingCategory.category.isNotEmpty) {
      return SvgPicture.asset(matchingCategory.image);
    } else {
      return ImageConstants(colors: AppColor.secondaryExtraSoft).avatar;
    }
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