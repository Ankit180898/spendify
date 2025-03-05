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
    Get.put(TransactionController());

    // Set the status bar color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF2C3E50), // Dark blue-gray
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Container(
      color: const Color(0xFF2C3E50), // Dark blue-gray
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColor.darkBackground,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Top Section with Gradient Background
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
                    TopBarContents(),
                    verticalSpace(8),
                    UserInfoCard(size: displayHeight(context) * 0.10),
                    verticalSpace(32),
                  ],
                ),
              ),

              // Main Content Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title (Optional)
                  // Text(
                  //   'Recent Transactions',
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.bold,
                  //     color: AppColor.secondary,
                  //   ),
                  // ),
                  // verticalSpace(16),

                  // Transactions List
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        const TransactionsContent(10), // Pass the initial limit
                        verticalSpace(16),

                        // Load More Button
                        Obx(() => controller.transactions.length >=
                                controller.limit.value
                            ? ElevatedButton(
                                onPressed: () => controller.loadMore(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Load More',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const SizedBox()),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
