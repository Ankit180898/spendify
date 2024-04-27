import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/utils/image_constants.dart';
import 'package:spendify/utils/utils.dart';

class TransactionListItem extends StatelessWidget {
  final RxList<Map<String, dynamic>> transaction;
  final index;

  const TransactionListItem(
      {super.key, required this.transaction, required this.index});

  @override
  Widget build(BuildContext context) {
    var trans = transaction[index];
    var i = transaction[index]['category'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
            radius: 24,
            backgroundColor: AppColor.primaryExtraSoft,
            child: getCategoryImage(i, categoryList)),
        title: Row(
          children: [
            Text(
              '${trans['description']}',
              style: mediumTextStyle(16, AppColor.secondary),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDateTime('${trans['date']}'),
              style: normalText(14, AppColor.secondarySoft),
            ),
            verticalSpace(5),
            Container(
              decoration: BoxDecoration(
                  color: AppColor.primarySoft,
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('$i',
                    style: normalText(14, Colors.white)),
              ),
            )
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            trans['type'] == 'expense'
                ? ImageConstants(colors: AppColor.warning).expense
                : ImageConstants(colors: AppColor.success).income,
            Text(
              "${trans['amount']}",
              style: mediumTextStyle(16, AppColor.secondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return DateFormat("MMMM d, y").format(dateTime);
  }

  Widget getCategoryImage(String category, List<CategoriesModel> categoryList) {
    var matchingCategory = categoryList.firstWhere(
      (element) => element.category == category,
      orElse: () => CategoriesModel(category: '', image: ''),
    );
    if (matchingCategory.category.isNotEmpty) {
      return SvgPicture.asset(matchingCategory.image);
    } else {
      return ImageConstants(colors: AppColor.secondaryExtraSoft).avatar;
    }
  }
}
