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
  var transactions = Transactions.income.obs;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.selectedCategory.value = '';
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SingleChildScrollView(
        child: Container(
          width: displayWidth(context),
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            color: AppColor.darkCard,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            children: <Widget>[
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        transactions.value = Transactions.income;
                        controller.selectedType.value = 'income';
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 24.0),
                        decoration: BoxDecoration(
                          color: transactions.value == Transactions.income
                              ? Colors.white // Selected color
                              : Colors.transparent, // Deselected color
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8.0),
                              bottomLeft: Radius.circular(8)),
                          border: Border.all(
                            color: Colors.white,
                          ),
                        ),
                        child: Row(
                          children: [
                            ImageConstants(
                                    colors: transactions.value ==
                                            Transactions.income
                                        ? AppColor.darkBackground
                                        : Colors.white)
                                .income,
                            const SizedBox(width: 8),
                            Text(
                              'Income',
                              style: normalText(
                                  16,
                                  transactions.value == Transactions.income
                                      ? AppColor.darkBackground
                                      : Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        transactions.value = Transactions.expense;
                        controller.selectedType.value = 'expense';
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 24.0),
                        decoration: BoxDecoration(
                          color: transactions.value == Transactions.expense
                              ? Colors.white // Selected color
                              : Colors.transparent, // Deselected color
                          borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8.0),
                              bottomRight: Radius.circular(8)),
                          border: Border.all(
                            color: Colors.white,
                          ),
                        ),
                        child: Row(
                          children: [
                            ImageConstants(
                                    colors: transactions.value ==
                                            Transactions.expense
                                        ? AppColor.darkBackground
                                        : Colors.white)
                                .expense,
                            const SizedBox(width: 8),
                            Text(
                              'Expense',
                              style: normalText(
                                  16,
                                  transactions.value == Transactions.expense
                                      ? AppColor.darkBackground
                                      : Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // () => SegmentedButton<Transactions>(
                //   style: ButtonStyle(
                //     backgroundColor: WidgetStateProperty.resolveWith<Color>(
                //       (Set<WidgetState> states) {
                //         if (states.contains(WidgetState.selected)) {
                //           return Colors.white;
                //         }
                //         return AppColor.primarySoft;
                //       },
                //     ),
                //     side: WidgetStateProperty.all<BorderSide>(
                //       const BorderSide(color: Colors.white),
                //     ),
                //     shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                //       const RoundedRectangleBorder(
                //         borderRadius: BorderRadius.all(Radius.circular(8)),
                //       ),
                //     ),
                //   ),
                //   showSelectedIcon: true,
                //   segments: <ButtonSegment<Transactions>>[
                //     ButtonSegment<Transactions>(
                //       enabled: true,
                //       value: Transactions.income,
                //       label: Text(
                //         'Income',
                //         style: normalText(16, AppColor.secondary),
                //       ),
                //       icon: ImageConstants(colors: AppColor.secondary).income,
                //     ),
                //     ButtonSegment<Transactions>(
                //       value: Transactions.expense,
                //       label: Text(
                //         'Expense',
                //         style: normalText(16, AppColor.secondary),
                //       ),
                //       icon: ImageConstants(colors: AppColor.secondary).expense,
                //     ),
                //   ],
                //   selected: <Transactions>{transactions.value},
                //   onSelectionChanged: (Set<Transactions> newSelection) {
                //     transactions.value = newSelection.first;
                //     controller.selectedType.value =
                //         newSelection.first == Transactions.income
                //             ? 'income'
                //             : 'expense';
                //   },
                // ),
              ),
              verticalSpace(16),
              Obx(() => AddTransactionTitle(controller.selectedType.value)),
              TransactionForm(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTransactionTitle extends StatelessWidget {
  final String transactionType;
  const AddTransactionTitle(this.transactionType, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Text(
        transactionType == 'income' ? 'Add Income' : 'Add Expense',
        style: mediumTextStyle(24, Colors.white),
      ),
    );
  }
}

class TransactionForm extends StatelessWidget {
  final TransactionController controller;
  const TransactionForm({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransactionInputField(
          controller: controller.amountController,
          label: "Amount",
          hintText: "Enter the amount",
          prefix: '₹',
        ),
        verticalSpace(8),
        TransactionInputField(
          controller: controller.titleController,
          label: "Title",
          hintText: "Enter the title",
        ),
        verticalSpace(8),
        Obx(
          () => CategoriesChips(
            categories: categoryList,
            onChanged: (value) => controller.selectedCategory.value = value!,
            selectedCategory: controller.selectedCategory.value,
          ),
        ),
        verticalSpace(16),
        Obx(
          () => CustomButton(
            text: controller.isLoading.isFalse ? "Add" : "...Loading",
            onPressed: () {
              if (controller.isLoading.isFalse) {
                controller.addResource();
              }
            },
            bgcolor: AppColor.darkSurface,
            height: displayHeight(context) * 0.07,
            width: displayWidth(context),
            textSize: 24,
            textColor: Colors.white,
          ),
        ),
        verticalSpace(16),
      ],
    );
  }
}

class TransactionInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? prefix;

  const TransactionInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: AppColor.cardGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 1, color: AppColor.secondaryExtraSoft),
      ),
      child: TextField(
        controller: controller,
        style: normalText(16, AppColor.secondarySoft),
        maxLines: 1,
        decoration: InputDecoration(
          label: Text(
            label,
            style: normalText(16, AppColor.secondarySoft),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: InputBorder.none,
          prefix: prefix != null
              ? Text(prefix!, style: normalText(16, AppColor.secondarySoft))
              : null,
          hintText: hintText,
          hintStyle: normalText(16, AppColor.secondarySoft),
        ),
      ),
    );
  }
}
