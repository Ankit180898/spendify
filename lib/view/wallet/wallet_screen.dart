import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/utils/image_constants.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';

import '../../config/app_color.dart';

enum Transactions { income, expense }

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransactionController());
    var transactions = Transactions.income.obs;

    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(displayHeight(context) * 0.30),
          child: AppBar(
            title: const Text("Wallet"),
            centerTitle: true,
          ),
        ),
        body: Obx(() => Column(children: <Widget>[
              SegmentedButton<Transactions>(
                  style: ButtonStyle(
                      side: MaterialStateProperty.all<BorderSide>(
                          BorderSide(color: AppColor.secondarySoft)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      backgroundColor:
                          const MaterialStatePropertyAll(Colors.white)),
                  showSelectedIcon: false,
                  selectedIcon: null,
                  segments: <ButtonSegment<Transactions>>[
                    ButtonSegment<Transactions>(
                      value: Transactions.income,
                      label: const Text('Income'),
                      icon: ImageConstants(colors: AppColor.secondary).income,
                    ),
                    ButtonSegment<Transactions>(
                      value: Transactions.expense,
                      label: const Text('Expense'),
                      icon: ImageConstants(colors: AppColor.secondary).expense,
                    ),
                  ],
                  selected: <Transactions>{transactions.value},
                  onSelectionChanged: (Set<Transactions> newSelection) {
                    transactions.value = newSelection.first;
                    controller.selectedType.value =
                        newSelection.first == Transactions.income
                            ? 'income'
                            : 'expense';
                  }),
              verticalSpace(16),
            ])));
  }
}
