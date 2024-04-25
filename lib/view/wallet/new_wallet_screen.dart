import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/widgets/bottom_navigation.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum Filtered { day, week, month }

class NewWalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final controller2 = Get.find<TransactionController>();
    var selectedFilter = 'day'.obs;

    var transactions = Filtered.day.obs;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: hideBottomAppBarController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  "Expenses",
                  style: TextStyle(fontSize: 24, color: AppColor.secondary),
                ),
              ),
              Center(
                child: SegmentedButton<Filtered>(
                  style: ButtonStyle(
                    enableFeedback: true,
                    side: MaterialStateProperty.all<BorderSide>(
                      BorderSide(color: AppColor.secondarySoft),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.white,
                    ),
                  ),
                  showSelectedIcon: false,
                  selectedIcon: null,
                  segments: const <ButtonSegment<Filtered>>[
                    ButtonSegment<Filtered>(
                      value: Filtered.day,
                      label: Text('Day'),
                    ),
                    ButtonSegment<Filtered>(
                      value: Filtered.week,
                      label: Text('Week'),
                    ),
                    ButtonSegment<Filtered>(
                      value: Filtered.month,
                      label: Text('Month'),
                    ),
                  ],
                  selected: <Filtered>{transactions.value},
                  onSelectionChanged: (Set<Filtered> newSelection) {
                    transactions.value = newSelection.first;
                    controller.selectedFilter.value =
                        newSelection.first == Filtered.day
                            ? 'day'
                            : newSelection.first == Filtered.week
                                ? 'week'
                                : 'month';
                    controller.updateChartData(newSelection.first.toString());
                  },
                ),
              ),
              verticalSpace(16),
              Center(
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(),
                  series: <CartesianSeries>[
                    LineSeries<Map<String, dynamic>, String>(
                      dataSource: controller.chartData,
                      xValueMapper: (data, _) => data['x'],
                      yValueMapper: (data, _) => data['y'],
                    ),
                  ],
                ),
              ),
              verticalSpace(16),
            ],
          ),
        ),
      ),
    );
  }
}
