import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/model/transaction_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TransactionBarGraph extends StatelessWidget {
  final TransactionController transactionController = Get.put(TransactionController());

   TransactionBarGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Summary'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GetBuilder<TransactionController>(
          init: transactionController,
          builder: (_) {
            return (_.transactions.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      const Text('Income and Expense Summary'),
                      const SizedBox(height: 10),
                      Expanded(
                        child: createBarChart(_.transactions),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget createBarChart(List<TransactionSummary> data) {
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: <CartesianSeries>[
        ColumnSeries<TransactionSummary, String>(
          dataSource: data,
          xValueMapper: (TransactionSummary summary, _) => summary.timePeriod,
          yValueMapper: (TransactionSummary summary, _) => summary.income,
          name: 'Income',
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
        ColumnSeries<TransactionSummary, String>(
          dataSource: data,
          xValueMapper: (TransactionSummary summary, _) => summary.timePeriod,
          yValueMapper: (TransactionSummary summary, _) => summary.expense,
          name: 'Expense',
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}
