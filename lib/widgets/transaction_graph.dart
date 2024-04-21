import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TransactionsGraph extends StatelessWidget {
  final controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: controller.getTransactions(), // Fetch transactions from Supabase
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show loading indicator while fetching data
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          // Extract data from the controller
          final List<Map<String, dynamic>> transactions =
              controller.transactions;

          // Process transactions data and prepare it for the chart
          final List<ChartData> chartData = _prepareChartData(transactions);

          return SfCartesianChart(
            legend: Legend(),
            borderColor: Colors.transparent,
            primaryXAxis: CategoryAxis(),
            primaryYAxis: NumericAxis(),
            series: <CartesianSeries>[
              ColumnSeries<ChartData, String>(
                dataSource: chartData,
                xValueMapper: (ChartData data, _) => data.category,
                name: "Expense",
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                enableTooltip: true,
                onPointTap: (pointInteractionDetails) => chartData,
                gradient: AppColor.primaryGradient,
                yValueMapper: (ChartData data, _) => data.amount,
              ),
            ],
          );
        }
      },
    );
  }

  List<ChartData> _prepareChartData(List<Map<String, dynamic>> transactions) {
    Map<String, double> categoryAmountMap = {};

    // Group transactions by category and calculate total amount for each category
    for (var transaction in transactions) {
      String category = transaction['category'];
      double amount = transaction['amount'].toDouble();

      if (categoryAmountMap.containsKey(category)) {
        categoryAmountMap[category] = categoryAmountMap[category]! + amount;
      } else {
        categoryAmountMap[category] = amount;
      }
    }

    // Convert the categoryAmountMap to a list of ChartData objects
    List<ChartData> chartData = categoryAmountMap.entries.map((entry) {
      return ChartData(
        category: entry.key,
        amount: entry.value,
      );
    }).toList();

    return chartData;
  }
}

class ChartData {
  final String category;
  final double amount;

  ChartData({required this.category, required this.amount});
}
