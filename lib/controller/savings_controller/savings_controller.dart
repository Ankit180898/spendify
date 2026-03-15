import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/savings_goal_model.dart';
import 'package:spendify/services/notification_service.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class SavingsController extends GetxController {
  var goals = <SavingsGoal>[].obs;
  var isLoading = false.obs;

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
          .from('savings_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      goals.value = response.map((m) => SavingsGoal.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error fetching savings goals: $e');
      CustomToast.errorToast('Error', 'Failed to load savings goals');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    required String emoji,
    DateTime? targetDate,
  }) async {
    try {
      final userId = supabaseC.auth.currentUser?.id;
      if (userId == null) return;
      await supabaseC.from('savings_goals').insert({
        'user_id': userId,
        'name': name,
        'target_amount': targetAmount,
        'emoji': emoji,
        if (targetDate != null)
          'target_date': targetDate.toIso8601String().substring(0, 10),
      });
      await fetchGoals();
      // Schedule deadline reminders if a target date was set
      if (targetDate != null) {
        final created = goals.firstWhereOrNull((g) =>
            g.name == name && g.targetAmount == targetAmount);
        if (created != null) {
          try {
            await NotificationService.scheduleSavingsReminder(
              goalId: created.id,
              goalName: created.name,
              targetDate: targetDate,
            );
          } catch (e) {
            debugPrint('Notification scheduling skipped: $e');
          }
        }
      }
      CustomToast.successToast('Goal created', 'Savings goal added');
    } catch (e) {
      debugPrint('Error adding savings goal: $e');
      CustomToast.errorToast('Error', 'Failed to create savings goal');
    }
  }

  Future<void> addSavings(String goalId, double amount) async {
    try {
      final goal = goals.firstWhereOrNull((g) => g.id == goalId);
      if (goal == null) return;
      final newSaved = goal.savedAmount + amount;
      await supabaseC
          .from('savings_goals')
          .update({'saved_amount': newSaved})
          .eq('id', goalId);
      final idx = goals.indexWhere((g) => g.id == goalId);
      if (idx != -1) goals[idx] = goal.copyWith(savedAmount: newSaved);
      if (newSaved >= goal.targetAmount) {
        CustomToast.successToast('Goal reached! 🎉', '${goal.name} is fully funded!');
        NotificationService.showMilestone(
          '${goal.emoji} Goal reached!',
          '${goal.name} is fully funded! Time to celebrate 🎉',
        );
      } else {
        final sym = Get.find<HomeController>().currencySymbol.value;
        CustomToast.successToast('Added!', '$sym${amount.toStringAsFixed(0)} saved toward ${goal.name}');
      }
    } catch (e) {
      debugPrint('Error updating savings: $e');
      CustomToast.errorToast('Error', 'Failed to update savings');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await supabaseC.from('savings_goals').delete().eq('id', goalId);
      goals.removeWhere((g) => g.id == goalId);
      await NotificationService.cancelSavingsReminder(goalId);
      CustomToast.successToast('Deleted', 'Savings goal removed');
    } catch (e) {
      debugPrint('Error deleting savings goal: $e');
      CustomToast.errorToast('Error', 'Failed to delete savings goal');
    }
  }
}
