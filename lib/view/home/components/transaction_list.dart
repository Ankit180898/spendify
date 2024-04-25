import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/utils/image_constants.dart';
import 'package:spendify/utils/utils.dart';

class TransactionsContent extends StatelessWidget {
  const TransactionsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0),
          child: Text(
            'Transactions',
            style: titleText(18, AppColor.secondary),
          ),
        ),
        Obx(
          () => controller.isLoading.value == true
              ? const CircularProgressIndicator()
              : controller.transactions.isNotEmpty
                  ? ListView.separated(
                      reverse: true,
                      padding: const EdgeInsets.all(0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.transactions.length,
                      itemBuilder: (context, index) {
                        var i = controller.transactions[index];
                        var category = i['category'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColor.primaryExtraSoft,
                                child:
                                    getCategoryImage(category, categoryList)),
                            title: Text(
                              '${i['description']}',
                              style: mediumTextStyle(16, AppColor.secondary),
                            ),
                            subtitle: Text(
                              _formatDateTime('${i['date']}'),
                              style: normalText(14, AppColor.secondarySoft),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                i['type'] == 'expense'
                                    ? ImageConstants(colors: AppColor.warning)
                                        .expense
                                    : ImageConstants(colors: AppColor.success)
                                        .income,
                                Text(
                                  "${i['amount']}",
                                  style:
                                      mediumTextStyle(16, AppColor.secondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Divider(
                            thickness: 0.5,
                            color: AppColor.secondaryExtraSoft,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: Text("No transactions"),
                    )),
        ),
      ],
    );
  }

// Function to parse and format date time string
  String _formatDateTime(String dateTimeString) {
    final dateTime =
        DateTime.parse(dateTimeString); // Parse the date time string
    return DateFormat("MMMM d, y").format(dateTime); // Format the date and time
  }

  // Function to get the category image based on the category name
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
