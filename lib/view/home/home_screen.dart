import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/home/components/income_expense_total.dart';
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
    debugPrint("email: ${controller.userEmail}");
    return Scaffold(
      backgroundColor: Colors.white54,
      body: Obx(
        () => SingleChildScrollView(
          controller: hideBottomAppBarController,
          child: Column(
            children: [
              TopBarContents(
                  username: controller.userName.toString(),
                  avatarUrl: "https://avatar.iran.liara.run/public/boy"),
              UserInfoCard(size: displayHeight(context) * 0.10),
              verticalSpace(32),
              const IncomeExpenseTotal(),
              TransactionsGraph(),
              const SingleChildScrollView(child: TransactionsContent()),
            ],
          ),
        ),
      ),
    );
  }
}
