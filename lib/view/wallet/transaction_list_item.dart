import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/utils/image_constants.dart';
import 'package:spendify/utils/utils.dart';
class TransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionListItem({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var category = transaction['category'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColor.secondaryExtraSoft,
          child: getCategoryImage(category),
        ),
        title: Text(
          '${transaction['description']}',
          style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text(
          _formatDateTime('${transaction['date']}'),
          style: TextStyle(fontSize: 14, color: AppColor.secondarySoft),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            transaction['type'] == 'expense'
                ? ImageConstants(colors: AppColor.warning).expense
                : ImageConstants(colors: AppColor.success).income,
            Text("${transaction['amount']}"),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return DateFormat("MMMM d, y").format(dateTime);
  }

  Widget getCategoryImage(String category) {
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
