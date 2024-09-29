import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/home/components/tabs_view.dart';
import 'package:spendify/view/home/components/top_bar_contents.dart';
import 'package:spendify/view/home/components/transaction_list.dart';
import 'package:spendify/widgets/bottom_navigation.dart';
import 'package:spendify/widgets/user_info_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final controller1 = Get.put(TransactionController());
    debugPrint("email: ${controller.userEmail}");

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: hideBottomAppBarController,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  gradient: AppColor.primaryGradient,
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28))),
              child: Column(
                children: [
                  Row(
                    children: [
                      const TopBarContents(),
                      const Spacer(),
                      IconButton(
                          onPressed: () {
                            controller.signOut();
                          },
                          icon: Icon(
                            Iconsax.logout,
                            color: AppColor.secondaryExtraSoft,
                          ))
                    ],
                  ),
                  UserInfoCard(size: displayHeight(context) * 0.10),
                  verticalSpace(32),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Categories',
                  style: titleText(18, AppColor.secondary),
                ),
              ),
            ),
            const TabsView(),

            //  TransactionsGraph(),
            const SingleChildScrollView(child: TransactionsContent()),
          ],
        ),
      ),
    );
  }
}
