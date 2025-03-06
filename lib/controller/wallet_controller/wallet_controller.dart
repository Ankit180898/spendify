import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class TransactionController extends GetxController {
  final amountController = TextEditingController();
  var selectedCategory = ''.obs; // Default selected category
  final titleController = TextEditingController();
  final selectedType = 'income'.obs;
  var isLoading = false.obs;
  var isSubmitted = false.obs;
  var selectedDate =
      DateTime.now().toIso8601String().obs; // Default to March 5, 2025
  final homeC = Get.find<HomeController>();

  @override
  void dispose() {
    super.dispose();
    amountController.dispose();
    titleController.dispose();
  }

  Future<void> addResource() async {
    try {
      isSubmitted.value = true;
      isLoading.value = true;
      var currentUser = supabaseC.auth.currentUser;

      // Validate amount before parsing
      if (amountController.text.isEmpty) {
        throw Exception("Amount cannot be empty");
      }

      // Parse amount from String to double
      double amount = double.parse(amountController.text);
      // Add resource
      final response = await supabaseC.from('transactions').insert({
        'user_id': currentUser!.id,
        'amount': amount, // Use parsed double value here
        'description': titleController.text,
        'type': selectedType.value,
        'category': selectedCategory.value,
        'date': selectedDate.value, // Use the selected date
      });

      // Update balance based on transaction type
      updateBalance(amount, selectedType.value);

      // Refresh balance and transactions
      homeC.getTransactions();
      homeC.incomeTransactions;
      homeC.expenseTransactions;

      // Clear text fields and selected category
      amountController.clear();
      titleController.clear();
      selectedCategory.value = '';
      selectedDate.value =
          DateTime(2025, 3, 5).toIso8601String(); // Reset to default date

      // Close the current screen
      Get.back();

      // Show success message
      CustomToast.successToast('Success', 'Transaction submitted successfully');
    } catch (e) {
      // Log the error for debugging
      debugPrint("Error in addResource: $e");
      // Clear text fields and selected category
      amountController.clear();
      titleController.clear();
      selectedCategory.value = '';
      selectedDate.value =
          DateTime(2025, 3, 5).toIso8601String(); // Reset to default date

      // Show error message if transaction submission fails
      CustomToast.errorToast('Failure', "Failed to submit!");
      throw Exception('Failed to add resource: $e');
    } finally {
      isLoading.value = false;
      isSubmitted.value = false;
    }
  }

  Future<void> updateBalance(double amount, String type) async {
    try {
      final response = await supabaseC
          .from("users")
          .select('balance')
          .eq('id', supabaseC.auth.currentUser!.id)
          .single();
      final currentBalance = response['balance'] as double? ?? 0.0;

      homeC.totalBalance.value =
          type == 'income' ? currentBalance + amount : currentBalance - amount;

      final updateResponse = await supabaseC
          .from("users")
          .update({'balance': homeC.totalBalance.value}).eq(
              'id', supabaseC.auth.currentUser!.id);

      // homeC.getBalance();
      homeC.getProfile();
      debugPrint("new bal: $updateResponse");
      // Check if the update was successful
      if (updateResponse.error == null) {
        debugPrint("User's balance updated successfully.");
      } else {
        debugPrint("Failed to update user's balance: ${updateResponse.error}");
      }
    } catch (error) {
      debugPrint("Error updating user's balance: $error");
    }
  }

  Future<void> addTransaction() async {
    final currentUser = supabaseC.auth.currentUser;

    if (amountController.text.isNotEmpty &&
        titleController.text.isNotEmpty &&
        selectedCategory.isNotEmpty) {
      isLoading.value = true;
      final response = await supabaseC.from('transactions').insert({
        'user_id': currentUser!.id,
        'amount': amountController.text,
        'description': titleController.text,
        'type': selectedType.value,
        'category': selectedCategory.value,
        'date': selectedDate.value,
      });
      debugPrint(response.toString());
      isLoading.value = false;
      selectedCategory.value = '';
      homeC.getTransactions();
      amountController.clear();
      titleController.clear();
      selectedDate.value =
          DateTime.now().toIso8601String(); // Reset to default date
      homeC.getProfile();

      Get.back();
      debugPrint('Transaction added successfully');
    } else {
      amountController.clear();
      titleController.clear();
      selectedCategory.value = '';
      selectedDate.value =
          DateTime.now().toIso8601String(); // Reset to default date
      CustomToast.errorToast(
          "ERROR", "Amount, title, and category are required");
    }
  }
}
