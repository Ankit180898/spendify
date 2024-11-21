import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/home/components/top_bar_contents.dart';
import 'package:spendify/view/home/components/transaction_list.dart';
import 'package:spendify/widgets/user_info_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final controller1 = Get.put(TransactionController());
     // Set the status bar color

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:
            AppColor.darkBackground, // Set status bar color
        statusBarIconBrightness: Brightness.light,
        // Icon color
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColor.darkBackground,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColor.darkGradientAlt,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        TopBarContents(),
                      ],
                    ),
                    UserInfoCard(size: displayHeight(context) * 0.10),
                    verticalSpace(32),
                  ],
                ),
              ),
              // Padding(
              //   padding:
              //       const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
              //   child: Align(
              //     alignment: Alignment.centerLeft,
              //     child: Text(
              //       'Categories',
              //       style: titleText(18, AppColor.secondary),
              //     ),
              //   ),
              // ),
              // const TabsView(),
              //  TransactionsGraph(),
              const SingleChildScrollView(child: TransactionsContent(10)),
            ],
          ),
        ),
      ),
    );
  }
}
