import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';

class TabsView extends StatelessWidget {
  const TabsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    // Select the "All" category chip by default when the widget is initialized

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: categoryList.map((category) {
          return InkWell(
            onTap: () {
              controller.filterTransactionsByCategory(category.category);
            },
            child: Obx(
              () => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  side: BorderSide(color: AppColor.primarySoft),
                  avatar: SvgPicture.asset(category.image,
                      color: controller.selectedChip.value == category.category
                          ? Colors.white
                          : AppColor.secondary),
                  label: Text(category.category,
                      style: normalText(
                          18,
                          controller.selectedChip.value == category.category
                              ? Colors.white
                              : AppColor.secondary)),
                  backgroundColor:
                      controller.selectedChip.value == category.category
                          ? AppColor.primarySoft
                          : Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
