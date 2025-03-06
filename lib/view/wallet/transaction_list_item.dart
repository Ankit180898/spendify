import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/model/categories_model.dart';
import '../../config/app_color.dart';
import '../../controller/home_controller/home_controller.dart';
import '../../utils/utils.dart';

class TransactionListItem extends StatelessWidget {
  final List<Map<String, dynamic>> transaction;
  final int index;
  final List<CategoriesModel> categoryList;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.index,
    required this.categoryList,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [
        //       AppColor.darkCard.withOpacity(0.8),
        //       AppColor.darkCard.withOpacity(0.6),
        //     ],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        //   borderRadius: BorderRadius.circular(16),
        //   border: Border.all(
        //     color: Colors.white.withOpacity(0.1),
        //     width: 1,
        //   ),
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black.withOpacity(0.2),
        //       blurRadius: 8,
        //       offset: const Offset(0, 4),
        //     ),
        //   ],
        // ),
        child: ListTile(
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              controller.getCategoryIcon(category, categoryList),
              color: Colors.white,
              size: 24,
            ),
          ),
          // leading: CircleAvatar(
          //   radius: 24,
          //   backgroundColor: AppColor.primaryExtraSoft,
          //   child: Icon(
          //     controller.getCategoryIcon(category, categoryList),
          //     size: 24,
          //   ),
          // ),
          title: Text(
            trans['description'].toString(),
            style: mediumTextStyle(16, Colors.white),
          ),
          subtitle: Text(
            controller.formatDateTime(trans['date'].toString()),
            style: normalText(14, AppColor.secondarySoft),
          ),
          trailing: Text(
            isExpense ? "-₹$amount" : "+₹$amount",
            style: mediumTextStyle(
              14,
              isExpense ? AppColor.error : AppColor.success,
            ),
          ),
        ),
      ),
    );
  }
}
