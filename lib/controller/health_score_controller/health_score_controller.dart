import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/savings_controller/savings_controller.dart';
import 'package:spendify/model/health_score_model.dart';
import 'package:spendify/model/savings_goal_model.dart';
import 'package:spendify/model/spending_goal_model.dart';
import 'package:spendify/services/health_score_service.dart';

class HealthScoreController extends GetxController {
  var score = Rxn<HealthScore>();
  var history = <HealthScore>[].obs; // up to 12 daily snapshots

  static const _prefKey = 'health_score_history_v1';

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
    // HomeController is registered in HomeScreen.build(), which hasn't run yet
    // at this point. Defer setup to after the first frame.
    Future.delayed(Duration.zero, _setupAndCompute);
  }

  void _setupAndCompute() {
    try {
      final homeC = Get.find<HomeController>();
      debounce(
        homeC.allTransactions,
        (_) => compute(),
        time: const Duration(milliseconds: 600),
      );
      compute();
    } catch (_) {
      // HomeController still not ready — retry once more after a short delay
      Future.delayed(const Duration(milliseconds: 300), _setupAndCompute);
    }
  }

  /// Recomputes the score from current data. Safe to call any time.
  /// Does nothing if there are fewer than 3 transactions — avoids showing
  /// a meaningless neutral score on fresh install.
  void compute() {
    try {
      final homeC = Get.find<HomeController>();
      final txs = homeC.allTransactions.toList();

      // Need at least some real data before showing a score
      if (txs.length < 3) return;

      GoalsController? goalsC;
      SavingsController? savingsC;
      try {
        goalsC = Get.find<GoalsController>();
      } catch (_) {}
      try {
        savingsC = Get.find<SavingsController>();
      } catch (_) {}

      final newScore = HealthScoreService.compute(
        allTransactions: txs,
        monthlyBudget: homeC.monthlyBudget.value,
        spendingGoals: goalsC?.goals.toList() ?? <SpendingGoal>[],
        savingsGoals: savingsC?.goals.toList() ?? <SavingsGoal>[],
      );

      score.value = newScore;
      _saveSnapshot(newScore);
    } catch (e) {
      debugPrint('HealthScoreController.compute error: $e');
    }
  }

  /// Change vs the most recent previous day's snapshot (null if no prior data).
  int? get weeklyChange {
    final current = score.value;
    if (current == null || history.length < 2) return null;
    final today = DateTime(
        current.computedAt.year,
        current.computedAt.month,
        current.computedAt.day);
    HealthScore? previous;
    for (final h in history.reversed) {
      final d = DateTime(h.computedAt.year, h.computedAt.month, h.computedAt.day);
      if (d.isBefore(today)) {
        previous = h;
        break;
      }
    }
    if (previous == null) return null;
    return current.total - previous.total;
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => HealthScore.fromJson(e as Map<String, dynamic>))
          .toList();
      history.value = list;
    } catch (e) {
      debugPrint('HealthScoreController._loadHistory error: $e');
    }
  }

  Future<void> _saveSnapshot(HealthScore s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime(s.computedAt.year, s.computedAt.month, s.computedAt.day);

      // One snapshot per day — replace today's if it already exists
      final updated = history
          .where((h) {
            final d = DateTime(h.computedAt.year, h.computedAt.month, h.computedAt.day);
            return d != today;
          })
          .toList();
      updated.add(s);

      // Keep last 12 snapshots (roughly 12 days / 12 weeks of weekly opens)
      if (updated.length > 12) updated.removeRange(0, updated.length - 12);

      history.value = updated;
      await prefs.setString(
          _prefKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('HealthScoreController._saveSnapshot error: $e');
    }
  }
}
