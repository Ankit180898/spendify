import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/main.dart';

import '../../widgets/toast/custom_toast.dart';

class TransactionController extends GetxController {
  final amountController = TextEditingController();
  var selectedCategory = ''.obs; // Default selected category
  final titleController = TextEditingController();
  final selectedType = 'income'.obs;
  var isLoading = false.obs;
  var isSubmitted = false.obs;
  final homeC = Get.find<HomeController>();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  @override
  void dispose() {
    super.dispose();
    amountController.dispose();
    titleController.dispose();
  }

  Future<void> addResource() async {
    try {
      // Set loading to true to display the loader
      isLoading.value = true;
      final currentUser = supabaseC.auth.currentUser;

      // Add resource
      final response = await supabaseC.from('transactions').insert({
        'user_id': currentUser!.id,
        'amount': amountController.text,
        'description': titleController.text,
        'type': selectedType.value,
        'category': selectedCategory.value,
        'date': DateTime.now().toIso8601String(),
      });
      if (selectedType.value == 'income') {
        updateBalance(amountController.text as double, 'income');
        homeC.getBalance();
      } else {
        updateBalance(amountController.text as double, 'expense');

        homeC.getBalance();
      }
      homeC.getTransactions();

      amountController.clear();
      titleController.clear();
      selectedCategory.value = '';
      Get.back();
      // Show Snackbar
      CustomToast.successToast('Success', 'Transaction submitted successfully');

      // If resource added successfully, fetch resources again to refresh the list
    } catch (e) {
      CustomToast.errorToast('Failure', "Failed to submit!");
      throw Exception('Failed to add resource: $e');
    } finally {
      // Set loading to false to hide the loader
      isLoading.value = false;
    }
  }

  Future<void> updateBalance(double amount, String type) async {
    try {
      // Fetch the current balance from the user's balance table
      final response = await supabaseC
          .from("users")
          .select('balance')
          .eq('user_id', supabaseC.auth.currentUser!.id)
          .single();
      final currentBalance = response['balance'];

      // Calculate the new balance based on the transaction type (income or expense)
      homeC.totalBalance =
          type == 'income' ? currentBalance + amount : currentBalance - amount;

      // Update the user's balance in the balance table
      final updateResponse = await supabaseC
          .from("users")
          .update({'balance': homeC.totalBalance}).eq(
              'user_id', supabaseC.auth.currentUser!.id);

      // Check if the update was successful
      if (updateResponse.error == null) {
        // Update successful
        debugPrint("User's balance updated successfully.");
      } else {
        // Update failed
        debugPrint("Failed to update user's balance: ${updateResponse.error}");
      }
    } catch (error) {
      // Handle errors
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
        'date': DateTime.now().toIso8601String(),
      });
      debugPrint(response);
      isLoading.value = false;
      selectedCategory.value = '';
      homeC.getTransactions();
      amountController.clear();
      titleController.clear();

      Get.back();

      // Transaction added successfully
      print('Transaction added successfully');
    } else {
      amountController.clear();
      titleController.clear();
      selectedCategory.value = '';
      CustomToast.errorToast(
          "ERROR", "Amount, title, and category are required");
    }
  }
}
