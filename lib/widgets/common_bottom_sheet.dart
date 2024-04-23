import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/utils/image_constants.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/widgets/categories_chips.dart';
import 'package:spendify/widgets/custom_button.dart';

enum Transactions { income, expense }

class BottomSheetExample extends StatefulWidget {
  const BottomSheetExample({super.key});

  @override
  State<BottomSheetExample> createState() => _BottomSheetExampleState();
}

class _BottomSheetExampleState extends State<BottomSheetExample> {
  final controller = Get.find<TransactionController>();
  @override
  Widget build(BuildContext context) {
    var transactions = Transactions.income.obs;

    return SingleChildScrollView(
      child: Container(
        width: displayWidth(context),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          minHeight: MediaQuery.of(context).size.height *
              0.3, // Set minimum height here
        ),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: SweepGradient(
              colors: [AppColor.primarySoft, Colors.white],
              endAngle: 20,
              startAngle: 10), // gradient: AppColor.primaryGradient,
          color: AppColor.secondaryExtraSoft,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Obx(
          () => Column(
            children: <Widget>[
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
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      transactions.value == Transactions.income
                          ? 'Add Income'
                          : 'Add Expense',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontFamily: 'poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  verticalSpace(8),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          width: 1, color: AppColor.secondaryExtraSoft),
                    ),
                    child: TextField(
                      controller: controller.amountController,
                      style:
                          const TextStyle(fontSize: 14, fontFamily: 'poppins'),
                      maxLines: 1,
                      decoration: InputDecoration(
                        label: Text(
                          "Amount",
                          style: TextStyle(
                            color: AppColor.secondarySoft,
                            fontSize: 14,
                          ),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: InputBorder.none,
                        prefix: Text(
                          '₹',
                          style: TextStyle(color: AppColor.secondarySoft),
                        ),
                        hintText: "100",
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontFamily: 'poppins',
                          fontWeight: FontWeight.w500,
                          color: AppColor.secondarySoft,
                        ),
                      ),
                    ),
                  ),
                  verticalSpace(8),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          width: 1, color: AppColor.secondaryExtraSoft),
                    ),
                    child: TextField(
                      controller: controller.titleController,
                      style:
                          const TextStyle(fontSize: 14, fontFamily: 'poppins'),
                      maxLines: 1,
                      decoration: InputDecoration(
                        label: Text(
                          "Title",
                          style: TextStyle(
                            color: AppColor.secondarySoft,
                            fontSize: 14,
                          ),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: InputBorder.none,
                        hintText: "Food",
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontFamily: 'poppins',
                          fontWeight: FontWeight.w500,
                          color: AppColor.secondarySoft,
                        ),
                      ),
                    ),
                  ),
                  verticalSpace(8),
                  CategoriesChips(
                    categories: categoryList,
                    onChanged: (value) =>
                        controller.selectedCategory.value = value!,
                    selectedCategory: controller.selectedCategory.value,
                  ),
                  verticalSpace(16),
                  CustomButton(
                      text: controller.isLoading.isFalse ? "Add" : "...Loading",
                      onPressed: () {
                        if (controller.isLoading.isFalse) {
                          controller.addResource();
                        }
                      },
                      bgcolor: AppColor.secondary,
                      height: displayHeight(context) * 0.08,
                      width: displayWidth(context),
                      textSize: 16,
                      textColor: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
