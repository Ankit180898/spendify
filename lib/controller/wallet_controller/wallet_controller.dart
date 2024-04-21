import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/transaction_model.dart';

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

  Future<void> addTransaction() async {
    final currentUser = supabaseC.auth.currentUser;

    if (amountController.text.isNotEmpty &&
        titleController.text.isNotEmpty &&
        selectedCategory.isNotEmpty) {
      isLoading.value = true;
      final double amount = double.parse(amountController.text);
      final response = await supabaseC.from('transactions').insert({
        'user_id': currentUser!.id,
        'amount': amountController.text,
        'description': titleController.text,
        'type': selectedType.value,
        'category': selectedCategory.value,
        'date': DateTime.now().toIso8601String(),
      });
      isLoading.value = false;
      homeC.getTransactions();

      if (response.error != null) {
        isLoading.value = false;
        amountController.clear();
        titleController.clear();
        Get.back();
      } else {
        // Check the type of transaction and update user balance accordingly
        if (selectedType.value == 'income') {
          await addIncomeToUser(currentUser.id, amount);
        } else {
          await deductExpenseFromUser(currentUser.id, amount);
        }
        isLoading.value = false;
        amountController.clear();
        titleController.clear();

        // Transaction added successfully
        print('Transaction added successfully');
      }
    } else {
      CustomToast.errorToast(
          "ERROR", "Amount, title, and category are required");
    }
  }

  Future<void> addIncomeToUser(String userId, double amount) async {
    final response = await supabaseC.from('users').update(
        {'balance': supabaseC.rpc('balance + $amount')}).eq('id', userId);

    if (response.error != null) {
      // Handle error
      print('Error updating user balance: ${response.error?.message}');
    } else {
      // User balance updated successfully
      print('User balance updated successfully');
    }
  }

  Future<void> deductExpenseFromUser(String userId, double amount) async {
    final response = await supabaseC.from('users').update(
        {'balance': supabaseC.rpc('balance - $amount')}).eq('id', userId);

    if (response.error != null) {
      // Handle error
      print('Error updating user balance: ${response.error?.message}');
    } else {
      // User balance updated successfully
      print('User balance updated successfully');
    }
  }
}
