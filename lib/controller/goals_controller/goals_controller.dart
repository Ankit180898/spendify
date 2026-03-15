import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/spending_goal_model.dart';
import 'package:spendify/services/notification_service.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class GoalsController extends GetxController {
  var goals = <SpendingGoal>[].obs;
  var isLoading = false.obs;

  // Lazily resolve HomeController when needed to avoid registration-order issues
  HomeController get _homeC => Get.find<HomeController>();

  @override
  void onInit() {
    super.onInit();
    fetchGoals();
  }

  Future<void> fetchGoals() async {
    isLoading.value = true;
    try {
      final userId = supabaseC.auth.currentUser?.id;
      if (userId == null) return;
      final response = await supabaseC
          .from('spending_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      goals.value = response.map((map) => SpendingGoal.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching goals: $e');
      CustomToast.errorToast('Error', 'Failed to load spending goals');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addGoal({
    required String category,
    required double limitAmount,
    required String period,
  }) async {
    try {
      final userId = supabaseC.auth.currentUser?.id;
      if (userId == null) return;
      await supabaseC.from('spending_goals').insert({
        'user_id': userId,
        'category': category,
        'limit_amount': limitAmount,
        'period': period,
      });
      await fetchGoals();
      CustomToast.successToast('Goal set', 'Spending limit saved successfully');
    } catch (e) {
      debugPrint('Error adding goal: $e');
      CustomToast.errorToast('Error', 'Failed to save spending goal');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await supabaseC.from('spending_goals').delete().eq('id', goalId);
      goals.removeWhere((g) => g.id == goalId);
      CustomToast.successToast('Deleted', 'Spending goal removed');
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      CustomToast.errorToast('Error', 'Failed to delete spending goal');
    }
  }

  /// Returns current spending for a goal's category & period from cached transactions.
  double currentSpending(SpendingGoal goal) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (goal.period == 'weekly') {
      start = DateTime(now.year, now.month, now.day - now.weekday + 1);
      end = start.add(const Duration(days: 6));
    } else {
      // monthly
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    }

    return _homeC.allTransactions
        .where((t) {
          if (t['type'] != 'expense') return false;
          if (goal.category != 'All' && t['category'] != goal.category) {
            return false;
          }
          final date = DateTime.tryParse(t['date'] ?? '');
          if (date == null) return false;
          return !date.isBefore(start) && !date.isAfter(end);
        })
        .fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0));
  }

  /// Called after every expense transaction. Alerts the user only when a threshold is crossed.
  void checkAndAlert(double addedAmount) {
    for (final goal in goals) {
      if (goal.limitAmount <= 0) continue;
      final spent = currentSpending(goal);
      final prevSpent = spent - addedAmount;
      final pct = spent / goal.limitAmount;
      final prevPct = prevSpent / goal.limitAmount;
      final label = goal.category == 'All' ? 'Total spending' : goal.category;
      final sym = Get.find<HomeController>().currencySymbol.value;

      if (prevPct < 1.0 && pct >= 1.0) {
        const title = 'Limit exceeded!';
        final body = '$label has crossed your $sym${goal.limitAmount.toStringAsFixed(0)} ${goal.period} limit';
        CustomToast.errorToast(title, body);
        NotificationService.showBudgetAlert(title: title, body: body);
      } else if (prevPct < 0.9 && pct >= 0.9) {
        const title = 'Approaching limit';
        final body = '$label is at ${(pct * 100).toStringAsFixed(0)}% of your $sym${goal.limitAmount.toStringAsFixed(0)} ${goal.period} limit';
        CustomToast.errorToast(title, body);
        NotificationService.showBudgetAlert(title: title, body: body);
      }
    }
  }
}
