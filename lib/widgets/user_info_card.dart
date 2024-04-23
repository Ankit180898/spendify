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
              gradient: LinearGradient(
                colors: [
                  Colors.white70.withOpacity(0.2),
                  AppColor.secondaryExtraSoft.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                verticalSpace(16),
                Text(
                  "Balance",
                  style: normalText(16, AppColor.secondaryExtraSoft),
                ),
                verticalSpace(8),
                Obx(
                  () => Text("₹${controller.totalBalance.value.toString()}",
                      style: titleText(40, AppColor.secondaryExtraSoft)),
                ),
                verticalSpace(8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          ImageConstants(colors: AppColor.success).income,
                          Column(
                            children: [
                              Text(
                                "Income",
                                style: TextStyle(
                                    color: AppColor.secondaryExtraSoft,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text('+ ₹${controller.totalIncome.value}',
                                  style: normalText(
                                      16, AppColor.secondaryExtraSoft)),
                            ],
                          )
                        ],
                      ),
                      Spacer(),
                      Row(
                        children: [
                          ImageConstants(colors: AppColor.success).income,
                          Column(
                            children: [
                              Text(
                                "Expense",
                                style: TextStyle(
                                    color: AppColor.secondaryExtraSoft,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text('+ ₹${controller.totalExpense.value}',
                                  style: normalText(
                                      16, AppColor.secondaryExtraSoft)),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          )),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
  //     child: Container(
  //       width: displayWidth(context),
  //       height: displayHeight(context) / 4,
  //       decoration: BoxDecoration(
  //           border: Border.all(
  //               color: AppColor.secondaryExtraSoft.withOpacity(0.15), width: 2),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withOpacity(0.15),
  //               spreadRadius: 0,
  //               blurRadius: 10,
  //               offset: Offset(0, 4),
  //             ),
  //           ],
  //           borderRadius: BorderRadius.circular(28),
  //           gradient: AppColor.primaryGradient),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
  //         child: Column(
  //           children: [
  //             verticalSpace(8),
  //             const Text(
  //               "Total Balance",
  //               style: TextStyle(color: Colors.white, fontSize: 14),
  //             ),
  //             verticalSpace(8),
  //             const Text(
  //               r'''$9844.00''',
  //               style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 32,
  //                   fontWeight: FontWeight.bold),
  //             ),
  //             verticalSpace(16),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [

  //                 Row(
  //                   children: [
  //                     IconButton.filled(onPressed: null, icon:ImageConstants(colors: AppColor.success).income,color:Colors.black.withOpacity(0.15) ,)
  //                      ,
  //                      horizontalSpace(8),
  //                     Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [

  //                         Text("Income",
  //                             style:
  //                                 TextStyle(color: Colors.white, fontSize: 14)),
  //                         verticalSpace(8),
  //                         const Text(
  //                           r'''$9844.00''',
  //                           style: TextStyle(
  //                               color: Colors.white,
  //                               fontSize: 14,
  //                               fontWeight: FontWeight.bold),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //                 Row(
  //                   children: [
  //                     IconButton.filled(onPressed: null, icon: ImageConstants(colors: AppColor.warning).expense,color:Colors.black.withOpacity(0.15) ,),
  //                     horizontalSpace(8),
  //                     Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text("Expense",
  //                             style:
  //                                 TextStyle(color: Colors.white, fontSize: 14)),
  //                         verticalSpace(8),
  //                         const Text(
  //                           r'''$9844.00''',
  //                           style: TextStyle(
  //                               color: Colors.white,
  //                               fontSize: 14,
  //                               fontWeight: FontWeight.bold),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             )
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
