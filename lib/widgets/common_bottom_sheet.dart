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
    controller.selectedCategory.value='';
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
          decoration: BoxDecoration(
            gradient: SweepGradient(
              colors: [AppColor.primarySoft, Colors.white],
              endAngle: 20,
              startAngle: 10,
            ),
            color: AppColor.secondaryExtraSoft,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            children: <Widget>[
              Obx(
                    () => SegmentedButton<Transactions>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return AppColor.primarySoft;
                      },
                    ),
                    side: WidgetStateProperty.all<BorderSide>(
                      const BorderSide(color: Colors.white),
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  showSelectedIcon: true,
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
                    controller.selectedType.value = newSelection.first == Transactions.income ? 'income' : 'expense';
                  },
                ),
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
          hintText: "100",
          prefix: '₹',
        ),
        verticalSpace(8),
        TransactionInputField(
          controller: controller.titleController,
          label: "Title",
          hintText: "Food",
        ),
        verticalSpace(8),
        Obx(()=>
           CategoriesChips(
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
            bgcolor: AppColor.secondary,
            height: displayHeight(context) * 0.08,
            width: displayWidth(context),
            textSize: 16,
            textColor: Colors.white,
          ),
        ),
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
        color: Colors.white,
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
          prefix: prefix != null ? Text(prefix!, style: normalText(16, AppColor.secondarySoft)) : null,
          hintText: hintText,
          hintStyle: normalText(16, AppColor.secondarySoft),
        ),
      ),
    );
  }
}
