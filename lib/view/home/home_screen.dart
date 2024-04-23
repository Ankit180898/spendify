import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/home/components/top_bar_contents.dart';
import 'package:spendify/view/home/components/transaction_list.dart';
import 'package:spendify/widgets/bottom_navigation.dart';
import 'package:spendify/widgets/transaction_graph.dart';
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
      backgroundColor: AppColor.secondary.withOpacity(0.6),
      body: SingleChildScrollView(
        controller: hideBottomAppBarController,
        child: Column(
          children: [
            TopBarContents(),
            UserInfoCard(size: displayHeight(context) * 0.10),
            verticalSpace(32),
            //  TransactionsGraph(),
            const SingleChildScrollView(child: TransactionsContent()),
          ],
        ),
      ),
    );
  }
}
