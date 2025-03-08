import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

      // Clear form
      resetForm();
      
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
      final response = await supabaseC
          .from("users")
          .select('balance')
          .eq('id', supabaseC.auth.currentUser!.id)
          .single();
      
      final currentBalance = response['balance'] as double? ?? 0.0;
      final newBalance = type == 'income' 
          ? currentBalance + amount 
          : currentBalance - amount;

      await supabaseC
          .from("users")
          .update({'balance': newBalance})
          .eq('id', supabaseC.auth.currentUser!.id);
      
      // Update local value
      homeC.totalBalance.value = newBalance;
      
      debugPrint("User's balance updated successfully to: $newBalance");
    } catch (error) {
      debugPrint("Error updating user's balance: $error");
      CustomToast.errorToast('Error', 'Failed to update balance');
    }
  }

  // This method is redundant with addResource and should be removed or merged
  Future<void> addTransaction() async {
    // Recommend removing this method as it duplicates functionality and
    // doesn't use the improved balance calculation logic
    await addResource();
  }
Future<void> deleteTransaction(String transactionId) async {
  try {
    // Fetch the transaction to get its amount and type
    final response = await supabaseC
        .from('transactions')
        .select()
        .eq('id', transactionId)
        .single();

    final amount = response['amount'] as double;
    final type = response['type'] as String;

    // Delete the transaction
    await supabaseC.from('transactions').delete().eq('id', transactionId);

    // Update the balance
    final currentBalance = homeC.totalBalance.value;
    if (type == 'income') {
      homeC.totalBalance.value = currentBalance - amount; // Subtract income
    } else {
      homeC.totalBalance.value = currentBalance + amount; // Add back expense
    }

    // Refresh transactions and balance
    await homeC.getTransactions();
    await homeC.fetchTotalBalanceData();
   
    CustomToast.successToast("Success", "Transaction deleted successfully");
    Get.back();
  } catch (e) {
    CustomToast.errorToast("Error", "Failed to delete transaction");
  }
}

Future<void> updateTransaction(String transactionId) async {
  try {
    // Fetch the old transaction to get its amount and type
    final oldTransaction = await supabaseC
        .from('transactions')
        .select()
        .eq('id', transactionId)
        .single();

    final oldAmount = oldTransaction['amount'] as double;
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

    // Update the balance
    final currentBalance = homeC.totalBalance.value;

    if (oldType == 'income') {
      homeC.totalBalance.value = currentBalance - oldAmount; // Subtract old income
    } else {
      homeC.totalBalance.value = currentBalance + oldAmount; // Add back old expense
    }

    if (newType == 'income') {
      homeC.totalBalance.value = currentBalance + newAmount; // Add new income
    } else {
      homeC.totalBalance.value = currentBalance - newAmount; // Subtract new expense
    }

    // Refresh transactions and balance
    await homeC.getTransactions();
    await homeC.fetchTotalBalanceData();

    CustomToast.successToast("Success", "Transaction updated successfully");
  } catch (e) {
    CustomToast.errorToast("Error", "Failed to update transaction");
  }
}
}