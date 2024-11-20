import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/image_constants.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(
          () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Container(
          width: displayWidth(context),
          height: displayHeight(context) / 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: AppColor.cardGradient
           
            
          ),
          child: Column(
            children: [
              verticalSpace(16),
              Text(
                "Balance",
                style: normalText(16, AppColor.secondaryExtraSoft),
              ),
              verticalSpace(8),
              Text(
                "₹${controller.totalBalance.value}",
                style: titleText(40, AppColor.secondaryExtraSoft),
              ),
              verticalSpace(8),
              _buildIncomeExpenseRow(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseRow(HomeController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIncomeInfo(controller),
          _buildExpenseInfo(controller),
        ],
      ),
    );
  }

  Widget _buildIncomeInfo(HomeController controller) {
    return Row(
      children: [
        ImageConstants(colors: AppColor.success).income,
        horizontalSpace(8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Income",
              style: TextStyle(
                color: AppColor.secondaryExtraSoft,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '+ ₹${controller.totalIncome.value}',
              style: normalText(16, AppColor.secondaryExtraSoft),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseInfo(HomeController controller) {
    return Row(
      children: [
        ImageConstants(colors: AppColor.warning).expense,
        horizontalSpace(8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Expense",
              style: TextStyle(
                color: AppColor.secondaryExtraSoft,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '- ₹${controller.totalExpense.value}',
              style: normalText(16, AppColor.secondaryExtraSoft),
            ),
          ],
        ),
      ],
    );
  }
}
