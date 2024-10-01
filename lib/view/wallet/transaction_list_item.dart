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
    var trans = transaction[index];
    var category = trans['category'];

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
          style: mediumTextStyle(16, AppColor.secondary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.formatDateTime(trans['date'].toString()),
              style: normalText(14, AppColor.secondarySoft),
            ),
            verticalSpace(5),
            Container(
              decoration: BoxDecoration(
                color: AppColor.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  category.toString(),
                  style: normalText(14, Colors.white),
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              trans['type'] == 'expense'
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: trans['type'] == 'expense'
                  ? AppColor.warning
                  : AppColor.success,
            ),
            const SizedBox(width: 8),
            Text(
              trans['amount'].toString(),
              style: mediumTextStyle(16, AppColor.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
