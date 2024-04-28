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
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return AppColor.primarySoft;
                      },
                    ),
                    side: MaterialStateProperty.all<BorderSide>(
                        const BorderSide(color: Colors.white)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  showSelectedIcon: true,
                  selectedIcon: null,
                  segments: <ButtonSegment<Transactions>>[
                    ButtonSegment<Transactions>(
                      enabled: true,
                      value: Transactions.income,
                      label: Text(
                        'Income',
                        style: normalText(16, AppColor.secondary),
                      ),
                      icon: ImageConstants(colors: AppColor.secondary).income,
                    ),
                    ButtonSegment<Transactions>(
                      value: Transactions.expense,
                      label: Text(
                        'Expense',
                        style: normalText(16, AppColor.secondary),
                      ),
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
                      controller.selectedType.value=='income'
                          ? 'Add Income'
                          : 'Add Expense',
                      style: mediumTextStyle(24, Colors.white),
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
                      style: normalText(16, AppColor.secondarySoft),
                      maxLines: 1,
                      decoration: InputDecoration(
                        label: Text(
                          "Amount",
                          style: normalText(16, AppColor.secondarySoft),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: InputBorder.none,
                        prefix: Text(
                          '₹',
                          style: normalText(16, AppColor.secondarySoft),
                        ),
                        hintText: "100",
                        hintStyle: normalText(16, AppColor.secondarySoft),
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
                          style: normalText(16, AppColor.secondarySoft),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: InputBorder.none,
                        hintText: "Food",
                        hintStyle: normalText(16, AppColor.secondarySoft),
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
