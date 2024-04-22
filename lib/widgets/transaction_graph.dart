import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TransactionsGraph extends StatelessWidget {
  final HomeController controller = Get.find<HomeController>();

  TransactionsGraph({Key? key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transactions = controller.transactions;

    final double totalIncome = transactions
        .where((transaction) => transaction['type'] == 'income')
        .map<double>((transaction) =>
            transaction['amount'].toDouble()) // Convert to double
        .fold(0, (prev, amount) => prev + amount);

    controller.totalIncome.value = totalIncome.toInt();

    final double totalExpense = transactions
        .where((transaction) => transaction['type'] == 'expense')
        .map<double>((transaction) =>
            transaction['amount'].toDouble()) // Convert to double
        .fold(0, (prev, amount) => prev + amount);
    controller.totalExpense.value = totalExpense.toInt();
    controller.totalBalance.value =
        controller.totalBalance.value + (totalIncome - totalExpense).toInt();

    final List<ChartData> data = [
      ChartData(category: 'Income', amount: totalIncome),
      ChartData(category: 'Expense', amount: totalExpense),
    ];

    return SingleChildScrollView(
      child: SizedBox(
        height: 300, // Set a finite height for the chart
        child: SfCircularChart(
          title: const ChartTitle(
            text: 'Income vs Expense',
          ),
          legend: const Legend(isVisible: true),
          series: <CircularSeries>[
            PieSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (ChartData data, _) => data.category,
              yValueMapper: (ChartData data, _) => data.amount,
              dataLabelMapper: (ChartData data, _) =>
                  '${data.category}: ${data.amount}',
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String category;
  final double amount;

  ChartData({required this.category, required this.amount});
}
