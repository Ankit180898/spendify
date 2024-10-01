import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';

class CategoriesGrid extends StatelessWidget {
  final HomeController homeController = Get.find<HomeController>();

  CategoriesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Map<String, double> totals = homeController.calculateTotalsByCategory();

      return GridView.builder(
        padding:
            const EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0, bottom: 24.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.0,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: categoryList.length, // Use categoryList length
        itemBuilder: (context, index) {
          var category = categoryList[index];
          var total = totals[category.category] ?? 0.0;

          return Container(
            height: MediaQuery.of(context).size.height * 0.20,
            decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: AppColor.primaryExtraSoft,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(20.0))),
            child: Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SvgPicture.asset(
                    category.image,
                    height: MediaQuery.of(context).size.width * 0.07,
                    width: MediaQuery.of(context).size.width * 0.07,
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.category,
                        style: mediumTextStyle(16, AppColor.secondary),
                      ),
                      Text("+ ₹${total.toStringAsFixed(2)}",
                          style: normalText(16, AppColor.success)),
                    ],
                  ), // Display the total income/expense
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
