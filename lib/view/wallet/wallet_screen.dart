import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/utils/image_constants.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/widgets/bottom_navigation.dart';

enum Filtered { income, expense }

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final controller2 = Get.find<TransactionController>();
    Map<String, double> dataMap = controller.calculateIncomeData();

    var transactions = Filtered.income.obs;
    var selectedFilter = 'income'.obs;
    return Scaffold(
        backgroundColor: Colors.white,
        body: Obx(
          () => SingleChildScrollView(
            controller: hideBottomAppBarController,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    "Transactions",
                    style: titleText(24, AppColor.secondary),
                  ),
                ),
                Obx(
                  () => Text(
                    "₹ ${controller.newBalance.value}",
                    style: TextStyle(
                        color: AppColor.secondary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                PieChart(
                  dataMap: dataMap,
                  centerText:
                      selectedFilter.value == 'income' ? 'Income' : 'Expense',
                  chartType: ChartType.ring,
                  chartRadius: MediaQuery.of(context).size.width / 2.5,
                  colorList: [
                    Colors.green,
                    Colors.red
                  ], // Colors for income and expense
                  legendOptions: LegendOptions(
                    showLegends: true,
                    legendPosition: LegendPosition.right,
                    showLegendsInRow: true,
                  ),
                  chartValuesOptions: ChartValuesOptions(
                    showChartValueBackground: true,
                    showChartValues: true,
                    showChartValuesInPercentage: true,
                    showChartValuesOutside: false,
                    decimalPlaces: 2,
                  ),
                ),
                verticalSpace(32),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: SegmentedButton<Filtered>(
                      style: ButtonStyle(
                          enableFeedback: true,
                          side: MaterialStateProperty.all<BorderSide>(
                              BorderSide(color: AppColor.secondarySoft)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          backgroundColor:
                              const MaterialStatePropertyAll(Colors.white)),
                      showSelectedIcon: false,
                      selectedIcon: null,
                      segments: <ButtonSegment<Filtered>>[
                        ButtonSegment<Filtered>(
                          value: Filtered.income,
                          label: const Text('Income'),
                          icon:
                              ImageConstants(colors: AppColor.secondary).income,
                        ),
                        ButtonSegment<Filtered>(
                          value: Filtered.expense,
                          label: const Text('Expense'),
                          icon: ImageConstants(colors: AppColor.secondary)
                              .expense,
                        ),
                      ],
                      selected: <Filtered>{transactions.value},
                      onSelectionChanged: (Set<Filtered> newSelection) {
                        transactions.value = newSelection.first;
                        selectedFilter.value =
                            newSelection.first == Filtered.income
                                ? 'income'
                                : 'expense';
                        if (newSelection.isNotEmpty) {
                          controller.filterTransactions(selectedFilter.value);
                        }
                      }),
                ),
                verticalSpace(16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 24.0, right: 24.0, top: 24.0),
                    child: Text(
                      transactions.value == Filtered.income
                          ? 'INCOME'
                          : 'EXPENSE',
                      style: TextStyle(
                          color: AppColor.secondarySoft,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
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
                                ? ImageConstants(colors: AppColor.warning)
                                    .expense
                                : ImageConstants(colors: AppColor.success)
                                    .income,
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
        ));
  }

  // Function to parse and format date time string
  String _formatDateTime(String dateTimeString) {
    final dateTime =
        DateTime.parse(dateTimeString); // Parse the date time string
    return DateFormat("d").format(dateTime); // Format the date and time
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
