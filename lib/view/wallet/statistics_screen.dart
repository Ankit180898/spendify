import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  void _showYearPicker(BuildContext context, HomeController controller) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.darkSurface.withOpacity(0.98),
                AppColor.darkBackground.withOpacity(0.98),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Year',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3, // Dynamic height based on screen size
                child: CupertinoPicker(
                  magnification: 1.3,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 50,
                  scrollController: FixedExtentScrollController(
                    initialItem: years.indexOf(controller.selectedYear.value),
                  ),
                  onSelectedItemChanged: (int selectedItem) {
                    controller.selectedYear.value = years[selectedItem];
                    controller.filterTransactions(controller.selectedFilter.value);
                    HapticFeedback.selectionClick();
                  },
                  selectionOverlay: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                        bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                    ),
                  ),
                  children: years
                      .map((year) => Center(
                            child: Text(
                              year.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColor.primary.withOpacity(0.5),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    controller.filterTransactions(controller.selectedFilter.value);
                    HapticFeedback.mediumImpact();
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColor.darkBackground,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.darkBackground,
        body: SafeArea(
          child: Obx(() => CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    backgroundColor: AppColor.darkBackground,
                    expandedHeight: MediaQuery.of(context).size.height * 0.15, // Dynamic height
                    pinned: true,
                    floating: true,
                    stretch: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        "Financial Insights",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColor.darkBackground,
                              AppColor.darkSurface.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 30),
                            child: Icon(
                              Icons.insights,
                              color: Colors.white.withOpacity(0.15),
                              size: 100,
                            ),
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      InkWell(
                        onTap: () => _showYearPicker(context, controller),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                controller.selectedYear.value.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 800),
                        child: _buildSummaryCards(controller),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildFilterAndChartSection(controller, context),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildSpendingBreakdown(controller, context),
                            ),
                          );
                        },
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildTopCategories(controller, context),
                            ),
                          );
                        },
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildMonthlyTrends(controller, context),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildMonthlyTrends(HomeController controller, BuildContext context) {
    final monthlyTotals = controller.calculateMonthlyTotals();
    final sortedMonths = monthlyTotals.keys.toList()
      ..sort((a, b) => DateFormat('MMM yyyy').parse(a).compareTo(DateFormat('MMM yyyy').parse(b)));

    final List<Map<String, dynamic>> monthlyData = sortedMonths.map((month) {
      return {
        'month': month,
        'income': monthlyTotals[month]!['income'] ?? 0.0,
        'expense': monthlyTotals[month]!['expense'] ?? 0.0,
        'savings': monthlyTotals[month]!['savings'] ?? 0.0,
      };
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.15),
            Colors.blueAccent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Trends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: Colors.blueAccent.withOpacity(0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4, // Dynamic height
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              zoomPanBehavior: ZoomPanBehavior(
                enablePinching: true,
                enablePanning: true,
                zoomMode: ZoomMode.x,
              ),
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                majorGridLines: const MajorGridLines(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                majorGridLines: MajorGridLines(
                  width: 1,
                  color: Colors.white.withOpacity(0.1),
                  dashArray: const <double>[5, 5],
                ),
                axisLine: const AxisLine(width: 0),
                numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
                labelFormat: '{value}',
              ),
              crosshairBehavior: CrosshairBehavior(
                enable: true,
                lineType: CrosshairLineType.both,
                lineDashArray: const <double>[5, 5],
                lineWidth: 1,
                lineColor: Colors.white.withOpacity(0.5),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                duration: 2000,
                canShowMarker: true,
                color: AppColor.darkSurface,
                borderColor: Colors.white.withOpacity(0.3),
                borderWidth: 1,
                textStyle: const TextStyle(color: Colors.white),
              ),
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                alignment: ChartAlignment.center,
                itemPadding: 15,
                textStyle: TextStyle(color: Colors.white, fontSize: 12),
                iconHeight: 12,
                iconWidth: 12,
                toggleSeriesVisibility: true,
              ),
              series: <CartesianSeries>[
                LineSeries<Map<String, dynamic>, String>(
                  name: 'Income',
                  dataSource: monthlyData,
                  xValueMapper: (Map<String, dynamic> data, _) => data['month'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['income'],
                  color: AppColor.success.withOpacity(0.9),
                  width: 3,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    shape: DataMarkerType.circle,
                    height: 8,
                    width: 8,
                    color: AppColor.success,
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                  animationDuration: 1800,
                  enableTooltip: true,
                ),
                LineSeries<Map<String, dynamic>, String>(
                  name: 'Expenses',
                  dataSource: monthlyData,
                  xValueMapper: (Map<String, dynamic> data, _) => data['month'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['expense'],
                  color: AppColor.error.withOpacity(0.9),
                  width: 3,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    shape: DataMarkerType.circle,
                    height: 8,
                    width: 8,
                    color: AppColor.error,
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                  animationDuration: 1800,
                  animationDelay: 500,
                  enableTooltip: true,
                ),
                AreaSeries<Map<String, dynamic>, String>(
                  name: 'Savings',
                  dataSource: monthlyData,
                  xValueMapper: (Map<String, dynamic> data, _) => data['month'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['savings'],
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.7),
                      Colors.blue.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderColor: Colors.blue,
                  borderWidth: 2,
                  animationDuration: 1800,
                  animationDelay: 1000,
                  enableTooltip: true,
                ),
              ],
              onTooltipRender: (TooltipArgs args) {
                args.header = args.dataPoints![0].point['month'];
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.blue.withOpacity(0.9),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your savings are trending upward",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You've improved your savings rate by ${controller.calculateSavingsChange().toStringAsFixed(0)}% compared to last month",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(HomeController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12, top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Colors.white70,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                // Replaced Flexible with Expanded
                child: _buildSummaryCard(
                  'Income',
                  controller.isAmountVisible.value
                      ? NumberFormat.currency(symbol: '₹').format(controller.totalIncome.value)
                      : '******',
                  Icons.arrow_upward,
                  AppColor.success,
                  () => controller.toggleVisibility(),
                  controller,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                // Replaced Flexible with Expanded
                child: _buildSummaryCard(
                  'Expenses',
                  controller.isAmountVisible.value
                      ? NumberFormat.currency(symbol: '₹').format(controller.totalExpense.value)
                      : '******',
                  Icons.arrow_downward,
                  AppColor.error,
                  () => controller.toggleVisibility(),
                  controller,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBalanceCard(controller),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String amount, IconData icon, Color color, VoidCallback onTap, HomeController controller) {
    double percentChange = 0.0;
    if (title == 'Income') {
      percentChange = controller.calculateIncomeChange();
    } else if (title == 'Expenses') {
      percentChange = controller.calculateExpenseChange();
    }

    String changeText =
        percentChange >= 0 ? '+${percentChange.toStringAsFixed(1)}%' : '${percentChange.toStringAsFixed(1)}%';
    bool isPositiveTrend = (title == 'Income' && percentChange >= 0) || (title == 'Expenses' && percentChange < 0);

    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.25),
                color.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                    color: isPositiveTrend ? AppColor.success : AppColor.error,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    changeText,
                    style: TextStyle(
                      color: isPositiveTrend ? AppColor.success : AppColor.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(HomeController controller) {
    final isPositive = controller.totalBalance.value >= 0;
    final balanceColor = isPositive ? AppColor.success : AppColor.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A2D3E),
            Color(0xFF1F1D36),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Balance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  controller.toggleVisibility();
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    controller.isAmountVisible.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: balanceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isPositive ? Icons.account_balance_wallet : Icons.warning_rounded,
                  color: balanceColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isAmountVisible.value
                        ? NumberFormat.currency(symbol: '₹').format(controller.totalBalance.value.abs())
                        : '******',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPositive ? AppColor.success.withOpacity(0.2) : AppColor.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPositive ? 'Available to spend' : 'Negative balance',
                          style: TextStyle(
                            color: isPositive ? AppColor.success : AppColor.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndChartSection(HomeController controller, BuildContext context) {
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 20),
              child: Text(
                'Income vs Expenses',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35, // Dynamic height
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: _buildTransactionChart(controller),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Income', AppColor.success.withOpacity(0.7)),
                  const SizedBox(width: 24),
                  _buildLegendItem('Expenses', AppColor.error.withOpacity(0.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(HomeController controller, String label, String filterType) {
    final isSelected = controller.selectedFilter.value == filterType;
    return GestureDetector(
      onTap: () {
        controller.selectedFilter.value = filterType;
        controller.filterTransactions(filterType);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.darkBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColor.darkCard : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColor.darkBackground.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
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
      primaryXAxis: CategoryAxis(
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        majorGridLines: const MajorGridLines(width: 0),
        labelRotation: 0,
        labelAlignment: LabelAlignment.center,
        labelPosition: ChartDataLabelPosition.outside,
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        majorGridLines: MajorGridLines(
          width: 1,
          color: Colors.white.withOpacity(0.1),
          dashArray: const <double>[5, 5],
        ),
        axisLine: const AxisLine(width: 0),
        numberFormat: NumberFormat.compact(),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        duration: 3000,
        color: AppColor.darkSurface,
        borderColor: Colors.white,
        textStyle: const TextStyle(color: Colors.white),
      ),
      series: <CartesianSeries>[
        ColumnSeries<Map<String, dynamic>, String>(
          name: 'Income',
          color: AppColor.success.withOpacity(0.7),
          dataSource: controller.filteredTransactions
              .where((transaction) =>
                  transaction['type'] == 'income' &&
                  DateTime.parse(transaction['date']).year == controller.selectedYear.value)
              .toList(),
          xValueMapper: (datum, _) {
            final date = DateTime.parse(datum['date']);
            return controller.selectedFilter.value == 'weekly'
                ? DateFormat('EEE').format(date)
                : DateFormat('MMM').format(date);
          },
          yValueMapper: (datum, _) => double.parse(datum['amount'].toString()),
          enableTooltip: true,
        ),
        ColumnSeries<Map<String, dynamic>, String>(
          name: 'Expense',
          color: AppColor.error.withOpacity(0.7),
          dataSource: controller.filteredTransactions
              .where((transaction) =>
                  transaction['type'] == 'expense' &&
                  DateTime.parse(transaction['date']).year == controller.selectedYear.value)
              .toList(),
          xValueMapper: (datum, _) {
            final date = DateTime.parse(datum['date']);
            return controller.selectedFilter.value == 'weekly'
                ? DateFormat('EEE').format(date)
                : DateFormat('MMM').format(date);
          },
          yValueMapper: (datum, _) => double.parse(datum['amount'].toString()),
          enableTooltip: true,
        ),
      ],
      onTooltipRender: (TooltipArgs args) {
        if (args.dataPoints != null && args.dataPoints!.isNotEmpty) {
          final dataPoint = args.dataPoints![0];
          args.header = dataPoint.x;
          args.text = '₹${dataPoint.y}';
        }
      },
    );
  }

  Widget _buildSpendingBreakdown(HomeController controller, BuildContext context) {
    Map<String, double> categoryTotals = controller.calculateTotalsByCategory();
    List<PieData> pieData = categoryTotals.entries.map((entry) => PieData(entry.key, entry.value)).toList();
    pieData.sort((a, b) => b.amount.compareTo(a.amount));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35, // Dynamic height
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SfCircularChart(
                margin: EdgeInsets.zero,
                legend: const Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  position: LegendPosition.bottom,
                  textStyle: TextStyle(color: Colors.white, fontSize: 12),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x: \$point.y',
                  color: AppColor.darkSurface,
                ),
                series: <CircularSeries>[
                  DoughnutSeries<PieData, String>(
                    dataSource: pieData,
                    xValueMapper: (PieData data, _) => data.category,
                    yValueMapper: (PieData data, _) => data.amount,
                    dataLabelMapper: (PieData data, _) => '${data.category}\n${NumberFormat.compactCurrency(
                      symbol: '\$',
                    ).format(data.amount)}',
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.inside,
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      connectorLineSettings: ConnectorLineSettings(
                        type: ConnectorType.curve,
                        length: '20%',
                      ),
                    ),
                    radius: '80%',
                    innerRadius: '50%',
                    explode: true,
                    explodeIndex: 0,
                    explodeOffset: '10%',
                    animationDuration: 1500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories(HomeController controller, BuildContext context) {
    Map<String, double> categoryTotals = controller.calculateTotalsByCategory();
    List<MapEntry<String, double>> sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<MapEntry<String, double>> topCategories = sortedCategories.take(5).toList();
    double totalAmount = sortedCategories.fold(0, (sum, item) => sum + item.value);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Categories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...topCategories.map((category) => _buildCategoryProgressBar(
                category.key,
                category.value,
                totalAmount,
                getCategoryColor(category.key),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressBar(String category, double amount, double total, Color color) {
    final percentage = total > 0 ? (amount / total * 100) : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // Note: 'bottom' should replace 'custom'
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                NumberFormat.currency(symbol: '\$').format(amount),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                height: 10,
                width: percentage.isFinite ? (percentage * (MediaQuery.of(Get.context!).size.width - 72) / 100) : 0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color getCategoryColor(String category) {
    final Map<String, Color> categoryColors = {
      'Food & Drink': Colors.orange,
      'Bills & Fees': Colors.pinkAccent,
      'Shopping': Colors.purple,
      'Housing': Colors.blue,
      'Transportation': Colors.green,
      'Health': Colors.red,
      'Entertainment': Colors.teal,
      'Personal': Colors.amber,
      'Education': Colors.indigo,
      'Travel': Colors.pink,
      'Utilities': Colors.cyan,
      'Groceries': Colors.deepOrange,
      'Investments': Colors.lightBlue,
      'Salary': AppColor.success,
      'Business': Colors.lightGreen,
    };
    return categoryColors[category] ?? Color((category.hashCode & 0xFFFFFF).toInt()).withOpacity(1.0);
  }
}

class PieData {
  final String category;
  final double amount;

  PieData(this.category, this.amount);
}
