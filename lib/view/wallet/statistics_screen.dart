import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/widgets/categories_grid.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/cupertino.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  void _showYearPicker(BuildContext context, HomeController controller) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.darkSurface.withOpacity(0.9),
                AppColor.darkBackground.withOpacity(0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Year',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 50,
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    controller
                        .filterTransactions(controller.selectedFilter.value);
                  },
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColor.darkBackground,
        systemNavigationBarColor: AppColor.darkBackground,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Financial Insights",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            InkWell(
              onTap: () => _showYearPicker(context, controller),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Obx(
                      () => Text(
                        controller.selectedYear.value.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterAndChartSection(controller),
                  _buildSpendingDetailsSection(),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildFilterAndChartSection(HomeController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Filter Segment Control
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterButton(
                  controller,
                  'Weekly',
                  'weekly',
                ),
                _buildFilterButton(
                  controller,
                  'Monthly',
                  'monthly',
                ),
              ],
            ),
          ),

          // Chart Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildTransactionChart(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
      HomeController controller, String label, String filterType) {
    final isSelected = controller.selectedFilter.value == filterType;
    return GestureDetector(
      onTap: () {
        controller.selectedFilter.value = filterType;
        controller.filterTransactions(filterType);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColor.darkBackground : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionChart(HomeController controller) {
    return SfCartesianChart(
      margin: const EdgeInsets.all(0),
      plotAreaBorderWidth: 0,
      primaryXAxis: const CategoryAxis(
        labelStyle: TextStyle(color: Colors.white, fontSize: 12),
        majorGridLines: MajorGridLines(width: 0),
        labelRotation: 45,
      ),
      primaryYAxis: NumericAxis(
        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        majorGridLines: MajorGridLines(
          width: 1,
          color: Colors.white.withOpacity(0.1),
        ),
        axisLine: const AxisLine(width: 0),
      ),
      series: <CartesianSeries>[
        ColumnSeries<Map<String, dynamic>, String>(
          name: 'Income',
          color: AppColor.success.withOpacity(0.7),
          dataSource: controller.filteredTransactions
              .where((transaction) =>
                  transaction['type'] == 'income' &&
                  DateTime.parse(transaction['date']).year ==
                      controller.selectedYear.value)
              .toList(),
          xValueMapper: (datum, _) {
            final date = DateTime.parse(datum['date']);
            return controller.selectedFilter.value == 'weekly'
                ? DateFormat('EEE').format(date)
                : DateFormat('MMM').format(date);
          },
          yValueMapper: (datum, _) => datum['amount'],
          borderRadius: BorderRadius.circular(8),
        ),
        ColumnSeries<Map<String, dynamic>, String>(
          name: 'Expense',
          color: AppColor.error.withOpacity(0.7),
          dataSource: controller.filteredTransactions
              .where((transaction) =>
                  transaction['type'] == 'expense' &&
                  DateTime.parse(transaction['date']).year ==
                      controller.selectedYear.value)
              .toList(),
          xValueMapper: (datum, _) {
            final date = DateTime.parse(datum['date']);
            return controller.selectedFilter.value == 'weekly'
                ? DateFormat('EEE').format(date)
                : DateFormat('MMM').format(date);
          },
          yValueMapper: (datum, _) => datum['amount'],
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  Widget _buildSpendingDetailsSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Text(
            'Spending Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CategoriesGrid(),
      ],
    );
  }
}
