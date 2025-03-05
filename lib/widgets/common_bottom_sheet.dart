import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/utils/image_constants.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/widgets/custom_button.dart';

enum Transactions { income, expense }

// Keep the existing categoryList as requested
final List<String> categoryList = [
  'Investments',
  'Health',
  'Bills & Fees',
  'Food & Drinks',
  'Car',
  'Groceries',
  'Gifts',
  'Transport',
];

class BottomSheetExample extends StatefulWidget {
  const BottomSheetExample({super.key});

  @override
  State<BottomSheetExample> createState() => _BottomSheetExampleState();
}

class _BottomSheetExampleState extends State<BottomSheetExample> {
  final controller = Get.find<TransactionController>();
  var transactions =
      Transactions.expense.obs; // Default to expense as per image

  @override
  void dispose() {
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
            color: AppColor.darkCard, // Keep dark card background as requested
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large TextField for amount at the top
              Container(
                width: displayWidth(context),
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: controller.amountController,
                  style: const TextStyle(
                    fontSize: 48, // Large, bold font as in the image
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '₹ 0.00',
                    hintStyle: TextStyle(
                      fontSize: 48,
                      color: AppColor.secondarySoft,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    // Ensure the value starts with '0.' if empty or invalid
                    if (value.isEmpty) {
                    } else if (!RegExp(r'^\d*\.?\d*$').hasMatch(value)) {
                      // Remove non-numeric characters except decimal point
                      String cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
                      controller.amountController.text = cleaned;
                    }
                  },
                ),
              ),
              // Segmented button for Income/Expense
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                              ? AppColor
                                  .whiteColor // White for selected, matching image
                              : Colors
                                  .transparent, // Transparent for unselected
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8.0),
                              bottomLeft: Radius.circular(8)),
                          border: Border.all(
                            color: AppColor.whiteColor, // White border
                          ),
                        ),
                        child: Row(
                          children: [
                            ImageConstants(colors: AppColor.whiteColor).income,
                            const SizedBox(width: 8),
                            Text(
                              'Income',
                              style: normalText(
                                  16,
                                  transactions.value == Transactions.income
                                      ? AppColor
                                          .darkBackground // Dark text on white
                                      : AppColor
                                          .whiteColor), // White text on transparent
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
                              ? AppColor
                                  .whiteColor // White for selected, matching image
                              : Colors
                                  .transparent, // Transparent for unselected
                          borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8.0),
                              bottomRight: Radius.circular(8)),
                          border: Border.all(
                            color: AppColor.whiteColor, // White border
                          ),
                        ),
                        child: Row(
                          children: [
                            ImageConstants(colors: AppColor.whiteColor).expense,
                            const SizedBox(width: 8),
                            Text(
                              'Expense',
                              style: normalText(
                                  16,
                                  transactions.value == Transactions.expense
                                      ? AppColor
                                          .darkBackground // Dark text on white
                                      : AppColor
                                          .whiteColor), // White text on transparent
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              verticalSpace(24),
              // Transaction Form Fields
              TransactionForm(controller: controller),
            ],
          ),
        ),
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
        // Title Field (labeled as "Name" in the image)
        TransactionInputField(
          isNumber: false,
          controller: controller.titleController,
          label: "Name",
          hintText: "Enter the name",
        ),
        verticalSpace(8),
        // Date Field
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: AppColor.cardGradient, // Keep gradient as requested
              borderRadius: BorderRadius.circular(8),
              border: Border.all(width: 1, color: AppColor.secondaryExtraSoft),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Date",
                  style: normalText(16, AppColor.secondarySoft),
                ),
                Obx(
                  () => Text(
                    DateFormat("MMM d, yyyy")
                        .format(DateTime.parse(controller.selectedDate.value)),
                    style: normalText(16, AppColor.whiteColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        verticalSpace(8),
        // Category Dropdown (replacing CategoriesChips)
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: AppColor.cardGradient, // Keep gradient as requested
            borderRadius: BorderRadius.circular(8),
            border: Border.all(width: 1, color: AppColor.secondaryExtraSoft),
          ),
          child: Obx(
            () => DropdownButtonFormField<String>(
              value: controller.selectedCategory.value.isEmpty
                  ? null
                  : controller.selectedCategory.value,
              decoration: InputDecoration(
                label: Text(
                  "Category",
                  style: normalText(16, AppColor.secondarySoft),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: InputBorder.none,
              ),
              items: categoryList.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: normalText(16, AppColor.whiteColor),
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  controller.selectedCategory.value = value;
                }
              },
              hint: Text(
                "Select a category",
                style: normalText(16, AppColor.secondarySoft),
              ),
              dropdownColor: AppColor
                  .darkCard, // Match the dark card background for dropdown
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 24),
              isExpanded: true,
              style: normalText(16, AppColor.whiteColor),
            ),
          ),
        ),
        verticalSpace(16),
        // Add Button (purple as in the image)
        Obx(
          () => CustomButton(
            text: controller.isLoading.isFalse ? "Add" : "...Loading",
            onPressed: () {
              if (controller.isLoading.isFalse) {
                controller.addResource();
              }
            },
            bgcolor: AppColor.darkSurface, // Match the image’s button color
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(controller.selectedDate.value),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.whiteColor,
              onPrimary: AppColor.darkSurface,
              surface: AppColor.darkCard,
              onSurface: Colors.white,
            ),
            dialogTheme:
                const DialogThemeData(backgroundColor: AppColor.darkCard),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.selectedDate.value = picked.toIso8601String();
    }
  }
}

class TransactionInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool? isNumber;
  final String hintText;
  final String? prefix;

  const TransactionInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.prefix,
    this.isNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: AppColor.cardGradient, // Keep gradient as requested
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 1, color: AppColor.secondaryExtraSoft),
      ),
      child: TextField(
        controller: controller,
        style: normalText(16, AppColor.whiteColor),
        maxLines: 1,
        undoController: UndoHistoryController(),
        keyboardType: isNumber == true
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
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
