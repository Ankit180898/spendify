import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_color.dart';
import '../../controller/home_controller/home_controller.dart';
import '../../utils/utils.dart';

class TransactionListItem extends StatelessWidget {
  final List<Map<String, dynamic>> transaction;
  final int index;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final trans = transaction[index];
    final category = trans['category'];
    final amount = trans['amount'].toString();
    final isExpense = trans['type'] == 'expense';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColor.primaryExtraSoft,
          child: controller.getCategoryImage(category, categoryList),
        ),
        title: Text(
          trans['description'].toString(),
          style: mediumTextStyle(16, Colors.white),
        ),
        subtitle: Text(
          controller.formatDateTime(trans['date'].toString()),
          style: normalText(14, AppColor.secondarySoft),
        ),
        trailing: Text(
          isExpense ? "-$amount" : "+$amount",
          style: mediumTextStyle(
            16,
            isExpense ? AppColor.error : AppColor.success,
          ),
        ),
      ),
    );
  }
}
