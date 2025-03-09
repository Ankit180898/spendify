import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';

class CommonBottomSheet extends StatefulWidget {
  const CommonBottomSheet({super.key});

  @override
  _CommonBottomSheetState createState() => _CommonBottomSheetState();
}

class _CommonBottomSheetState extends State<CommonBottomSheet> {
  final controller = Get.find<TransactionController>();
  final _transactionType = Transactions.income.obs;

  // Enhanced category list with icons
  final List<CategoryItem> _categories = [
    CategoryItem(name: 'Investments', icon: Icons.trending_up),
    CategoryItem(name: 'Health', icon: Icons.medical_services_outlined),
    CategoryItem(name: 'Bills & Fees', icon: Icons.receipt_long),
    CategoryItem(name: 'Food & Drinks', icon: Icons.restaurant),
    CategoryItem(name: 'Car', icon: Icons.directions_car),
    CategoryItem(name: 'Groceries', icon: Icons.shopping_cart),
    CategoryItem(name: 'Gifts', icon: Icons.card_giftcard),
    CategoryItem(name: 'Transport', icon: Icons.transit_enterexit),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF1A2533)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                _buildAmountInput(),
                _buildTransactionTypeSelector(),
                _buildCategoryGrid(),
                _buildDateAndNameInputs(),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _transactionType.value == Transactions.income ? "INCOME AMOUNT" : "EXPENSE AMOUNT",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 48,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: TextField(
                  controller: controller.amountController,
                  style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: Colors.white,
                  cursorWidth: 2.0,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 48,
                      color: Colors.white.withOpacity(0.3),
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          Container(
            height: 1,
            width: MediaQuery.of(context).size.width * 0.7,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTypeButton(Transactions.income, 'Income', Icons.arrow_upward_rounded),
            _buildTypeButton(Transactions.expense, 'Expense', Icons.arrow_downward_rounded),
          ],
        ));
  }

  Widget _buildTypeButton(Transactions type, String label, IconData icon) {
    bool isSelected = _transactionType.value == type;
    return GestureDetector(
      onTap: () {
        debugPrint('Selected Type: $type');

        _transactionType.value = type; // Update the local observable
        controller.selectedType.value = type == Transactions.income ? 'income' : 'expense'; // Update the controller
        debugPrint('Updated selectedType in controller: ${controller.selectedType.value}');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColor.darkBackground : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColor.darkBackground : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryItem(_categories[index]);
        },
      ),
    );
  }

  Widget _buildCategoryItem(CategoryItem category) {
    return Obx(() {
      final isSelected = controller.selectedCategory.value == category.name;
      return GestureDetector(
        onTap: () {
          controller.selectedCategory.value = category.name;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDateAndNameInputs() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Date',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Obx(() => Text(
                      DateFormat("MMM d, yyyy").format(DateTime.parse(controller.selectedDate.value)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: TextField(
            controller: controller.titleController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Transaction Name',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => GestureDetector(
          onTap: controller.isLoading.isFalse ? () => controller.addResource() : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Center(
              child: Text(
                controller.isLoading.isFalse ? 'Add Transaction' : 'Processing...',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(controller.selectedDate.value),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              surface: AppColor.darkSurface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColor.darkBackground,
            ),
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

class CategoryItem {
  final String name;
  final IconData icon;

  CategoryItem({required this.name, required this.icon});
}

enum Transactions { income, expense }
