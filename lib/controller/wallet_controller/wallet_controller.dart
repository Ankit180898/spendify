import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class TransactionController extends GetxController {
  final amountController = TextEditingController();
  var selectedCategory = ''.obs;
  final titleController = TextEditingController();
  final selectedType = 'income'.obs;
  var isLoading = false.obs;
  var isSubmitted = false.obs;
  var selectedDate = DateTime.now().toIso8601String().obs;
  final homeC = Get.find<HomeController>();

  @override
  void dispose() {
    super.dispose();
    amountController.dispose();
    titleController.dispose();
  }

  Future<void> addResource() async {
    try {
      // Validate inputs first
      if (amountController.text.isEmpty) {
        CustomToast.errorToast('Error', 'Amount cannot be empty');
        return;
      }

      if (titleController.text.isEmpty) {
        CustomToast.errorToast('Error', 'Title cannot be empty');
        return;
      }

      if (selectedCategory.value.isEmpty) {
        CustomToast.errorToast('Error', 'Please select a category');
        return;
      }

      isSubmitted.value = true;
      isLoading.value = true;
      var currentUser = supabaseC.auth.currentUser;

      // Parse amount from String to double
      double amount;
      try {
        amount = double.parse(amountController.text);
      } catch (e) {
        CustomToast.errorToast('Error', 'Please enter a valid amount');
        isLoading.value = false;
        isSubmitted.value = false;
        return;
      }

      // Add resource
      await supabaseC.from('transactions').insert({
        'user_id': currentUser!.id,
        'amount': amount,
        'description': titleController.text,
        'type': selectedType.value,
        'category': selectedCategory.value,
        'date': selectedDate.value,
      });

      // Update balance based on transaction type
      await updateBalance(amount, selectedType.value);

      // Fetch complete balance data first (to fix the main issue)
      await homeC.fetchTotalBalanceData();

      // Then get paginated transactions for display
      await homeC.getTransactions();

      // Check spending goals if this was an expense
      if (selectedType.value == 'expense') {
        final goalsC = Get.find<GoalsController>();
        goalsC.checkAndAlert();
      }

      // Clear form
      resetForm();
      selectedType.value = 'income'; // Reset to default

      // Close the current screen
      Get.back();

      // Show success message
      CustomToast.successToast('Success', 'Transaction submitted successfully');
    } catch (e) {
      // Log the error for debugging
      debugPrint("Error in addResource: $e");

      // Show error message if transaction submission fails
      CustomToast.errorToast('Failure', "Failed to submit transaction");
    } finally {
      isLoading.value = false;
      isSubmitted.value = false;
    }
  }

  void resetForm() {
    amountController.clear();
    titleController.clear();
    selectedCategory.value = '';
    selectedDate.value = DateTime.now().toIso8601String();
  }

  Future<void> updateBalance(double amount, String type) async {
    try {
      final response =
          await supabaseC.from("users").select('balance').eq('id', supabaseC.auth.currentUser!.id).single();

      final currentBalance = (response['balance'] as num).toDouble();
      final newBalance = type == 'income' ? currentBalance + amount : currentBalance - amount;

      await supabaseC.from("users").update({'balance': newBalance}).eq('id', supabaseC.auth.currentUser!.id);

      // Update local value
      homeC.totalBalance.value = newBalance;

      debugPrint("User's balance updated successfully to: $newBalance");
    } catch (error) {
      debugPrint("Error updating user's balance: $error");
      CustomToast.errorToast('Error', 'Failed to update balance');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      isLoading.value = true;
      // Fetch the transaction to get its amount and type
      final response = await supabaseC.from('transactions').select().eq('id', transactionId).single();

      final amount = (response['amount'] as num).toDouble();
      final type = response['type'] as String;

      // Delete the transaction
      await supabaseC.from('transactions').delete().eq('id', transactionId);

      // Update the balance
      final currentBalance = homeC.totalBalance.value;
      if (type == 'income') {
        homeC.totalBalance.value = currentBalance - amount;
      } else {
        homeC.totalBalance.value = currentBalance + amount;
      }

      // Refresh transactions and balance
      await homeC.getTransactions();
      await homeC.fetchTotalBalanceData();

      CustomToast.successToast("Success", "Transaction deleted successfully");
    } catch (e) {
      CustomToast.errorToast("Error", "Failed to delete transaction");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTransaction(String transactionId) async {
    try {
      isLoading.value = true;
      // Fetch the old transaction to get its amount and type
      final oldTransaction = await supabaseC.from('transactions').select().eq('id', transactionId).single();

      final oldAmount = (oldTransaction['amount'] as num).toDouble();
      final oldType = oldTransaction['type'] as String;

      // Parse the new amount
      final newAmount = double.tryParse(amountController.text) ?? 0.0;
      final newType = selectedType.value;

      // Update the transaction
      await supabaseC.from('transactions').update({
        'amount': newAmount,
        'description': titleController.text,
        'category': selectedCategory.value,
        'type': newType,
        'date': selectedDate.value,
      }).eq('id', transactionId);

      // Update the balance: reverse old transaction then apply new one
      double updatedBalance = homeC.totalBalance.value;

      if (oldType == 'income') {
        updatedBalance -= oldAmount; // Reverse old income
      } else {
        updatedBalance += oldAmount; // Reverse old expense
      }

      if (newType == 'income') {
        updatedBalance += newAmount; // Apply new income
      } else {
        updatedBalance -= newAmount; // Apply new expense
      }

      homeC.totalBalance.value = updatedBalance;

      // Refresh transactions and balance
      await homeC.getTransactions();
      await homeC.fetchTotalBalanceData();

      CustomToast.successToast("Success", "Transaction updated successfully");
      Get.back(result: true);
    } catch (e) {
      CustomToast.errorToast("Error", "Failed to update transaction");
    } finally {
      isLoading.value = false;
    }
  }
}
