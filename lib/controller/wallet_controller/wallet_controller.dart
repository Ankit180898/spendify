import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/services/notification_service.dart';
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

  Future<void> addResource({bool silent = false}) async {
    try {
      // Validate inputs first
      if (amountController.text.isEmpty) {
        if (!silent) { CustomToast.errorToast('Error', 'Amount cannot be empty'); }
        return;
      }

      if (titleController.text.isEmpty) {
        if (!silent) { CustomToast.errorToast('Error', 'Title cannot be empty'); }
        return;
      }

      if (selectedCategory.value.isEmpty) {
        if (!silent) { CustomToast.errorToast('Error', 'Please select a category'); }
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
        if (!silent) { CustomToast.errorToast('Error', 'Please enter a valid amount'); }
        isLoading.value = false;
        isSubmitted.value = false;
        return;
      }

      // Add resource
      if (currentUser == null) {
        if (!silent) CustomToast.errorToast('Error', 'Not signed in');
        return;
      }
      await supabaseC.from('transactions').insert({
        'user_id': currentUser.id,
        'amount': amount,
        'description': titleController.text,
        'type': selectedType.value,
        'category': selectedCategory.value,
        'date': selectedDate.value,
      });

      // Update balance based on transaction type
      await updateBalance(amount, selectedType.value);

      if (!silent) {
        // Fetch complete balance data first (to fix the main issue)
        await homeC.fetchTotalBalanceData();

        // Then get paginated transactions for display
        await homeC.getTransactions();

        // Check spending goals if this was an expense
        if (selectedType.value == 'expense') {
          final goalsC = Get.find<GoalsController>();
          goalsC.checkAndAlert(amount);

          // Check monthly budget threshold crossings
          final budget = homeC.monthlyBudget.value;
          if (budget > 0) {
            final now = DateTime.now();
            final monthStart = DateTime(now.year, now.month, 1);
            final monthSpent = homeC.allTransactions
                .where((t) {
                  final d = DateTime.tryParse(t['date'] ?? '');
                  return d != null &&
                      !d.isBefore(monthStart) &&
                      t['type'] == 'expense';
                })
                .fold(0.0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0.0));
            final prevSpent = monthSpent - amount;
            final sym = homeC.currencySymbol.value;

            if (prevSpent / budget < 1.0 && monthSpent / budget >= 1.0) {
              NotificationService.showBudgetAlert(
                title: 'Monthly budget exceeded!',
                body: 'You\'ve gone over your $sym${budget.toStringAsFixed(0)} monthly budget.',
              );
            } else if (prevSpent / budget < 0.8 && monthSpent / budget >= 0.8) {
              NotificationService.showBudgetAlert(
                title: '80% of monthly budget used',
                body: '$sym${(budget - monthSpent).toStringAsFixed(0)} left for the rest of the month.',
              );
            }
          }
        }

        // Reset log reminder — fires in 3 days if no new transaction is logged
        NotificationService.rescheduleLogReminder();

        // Spend spike detection
        _checkSpendSpike(selectedType.value, amount);

        // Under-budget milestone (last 2 days of month)
        _checkUnderBudgetMilestone();

        // Clear form
        resetForm();
        selectedType.value = 'income'; // Reset to default

        // Close the current screen
        Get.back();

        // Show success message
        CustomToast.successToast('Success', 'Transaction submitted successfully');
      }
    } catch (e) {
      // Log the error for debugging
      debugPrint("Error in addResource: $e");

      if (!silent) {
        // Show error message if transaction submission fails
        CustomToast.errorToast('Failure', "Failed to submit transaction");
      }
      rethrow; // Let batch importers handle individual errors
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
      final uid = supabaseC.auth.currentUser?.id;
      if (uid == null) return;

      // Use the locally cached balance (always recomputed from all transactions by
      // fetchTotalBalanceData) instead of reading from users.balance, which can be
      // stale after delete/edit operations that don't update the users table.
      final currentBalance = homeC.totalBalance.value;
      final newBalance = type == 'income' ? currentBalance + amount : currentBalance - amount;

      await supabaseC.from("users").update({'balance': newBalance}).eq('id', uid);

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

  void _checkSpendSpike(String txType, double amount) {
    if (txType != 'expense') return;
    try {
      final txs = homeC.allTransactions;
      final sym = homeC.currencySymbol.value;
      final category = selectedCategory.value;
      if (category.isEmpty) return;

      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);

      double thisWeek = txs.where((t) {
        final d = t['parsedDate'] as DateTime?;
        return d != null &&
            !d.isBefore(startOfWeek) &&
            t['type'] == 'expense' &&
            t['category'] == category;
      }).fold(0.0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));

      // Average weekly spend in this category over the previous 4 weeks
      double totalPast4 = 0;
      for (int w = 1; w <= 4; w++) {
        final wStart = startOfWeek.subtract(Duration(days: 7 * w));
        final wEnd = startOfWeek.subtract(Duration(days: 7 * (w - 1)));
        totalPast4 += txs.where((t) {
          final d = t['parsedDate'] as DateTime?;
          return d != null &&
              !d.isBefore(wStart) &&
              d.isBefore(wEnd) &&
              t['type'] == 'expense' &&
              t['category'] == category;
        }).fold(0.0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));
      }
      final avg = totalPast4 / 4;

      // Alert only when average is meaningful and this week is 50%+ above it
      if (avg > 100 && thisWeek > avg * 1.5) {
        NotificationService.showSpendSpike(
          category: category,
          thisWeek: thisWeek,
          avgWeek: avg,
          sym: sym,
        );
      }
    } catch (e) {
      debugPrint('_checkSpendSpike error: $e');
    }
  }

  void _checkUnderBudgetMilestone() {
    try {
      final budget = homeC.monthlyBudget.value;
      if (budget <= 0) return;

      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      if (now.day < daysInMonth - 1) return; // Only last 2 days of month

      final monthStart = DateTime(now.year, now.month, 1);
      final monthSpent = homeC.allTransactions.where((t) {
        final d = t['parsedDate'] as DateTime?;
        return d != null && !d.isBefore(monthStart) && t['type'] == 'expense';
      }).fold(0.0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));

      if (monthSpent >= budget) return;

      final sym = homeC.currencySymbol.value;
      final saved = budget - monthSpent;
      NotificationService.showMilestone(
        'Under budget this month! 🎉',
        'You stayed $sym${saved.toStringAsFixed(0)} under your budget. Great discipline!',
      );
    } catch (e) {
      debugPrint('_checkUnderBudgetMilestone error: $e');
    }
  }
}
