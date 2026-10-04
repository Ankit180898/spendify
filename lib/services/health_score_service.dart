import 'package:spendify/model/health_score_model.dart';
import 'package:spendify/model/savings_goal_model.dart';
import 'package:spendify/model/spending_goal_model.dart';

/// Pure, stateless health score computation.
/// Call compute() with the current data and get a HealthScore back.
/// No GetX, no Supabase, no side effects — easy to test.
class HealthScoreService {
  static HealthScore compute({
    required List<Map<String, dynamic>> allTransactions,
    required double monthlyBudget,
    required List<SpendingGoal> spendingGoals,
    required List<SavingsGoal> savingsGoals,
  }) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    double amt(Map<String, dynamic> t) =>
        (t['amount'] as num?)?.toDouble() ?? 0.0;

    DateTime? parseDate(Map<String, dynamic> t) =>
        t['parsedDate'] as DateTime? ?? DateTime.tryParse(t['date'] ?? '');

    final thisMonthTx = allTransactions.where((t) {
      final d = parseDate(t);
      return d != null && !d.isBefore(monthStart);
    }).toList();

    final monthIncome = thisMonthTx
        .where((t) => t['type'] == 'income')
        .fold(0.0, (s, t) => s + amt(t));
    final monthExpense = thisMonthTx
        .where((t) => t['type'] == 'expense')
        .fold(0.0, (s, t) => s + amt(t));

    final savings = _savingsScore(monthIncome, monthExpense);
    final budget = _budgetScore(spendingGoals, allTransactions, now, monthlyBudget, monthExpense, parseDate, amt);
    final goal = _goalScore(savingsGoals, now);
    final consistency = _consistencyScore(allTransactions, parseDate, amt, now);

    // Weighted sum — savings 30%, budget 25%, goal 25%, consistency 20%
    final total = (savings * 0.30 + budget * 0.25 + goal * 0.25 + consistency * 0.20)
        .round()
        .clamp(0, 100);

    return HealthScore(
      total: total,
      savingsScore: savings,
      budgetScore: budget,
      goalScore: goal,
      consistencyScore: consistency,
      computedAt: now,
    );
  }

  // ── Component 1: Savings Rate ──────────────────────────────────────────────
  // How much of income is being saved this month.
  // >30% → 100, 20% → 80, 10% → 60, 0% → 40, negative scales down to 0.
  static int _savingsScore(double income, double expense) {
    if (income <= 0) return 50;
    final rate = (income - expense) / income;
    if (rate >= 0.30) return 100;
    if (rate >= 0.20) return 80;
    if (rate >= 0.10) return 60;
    if (rate >= 0.00) return 40;
    return (40 + rate * 100).clamp(0, 40).round();
  }

  // ── Component 2: Budget Adherence ─────────────────────────────────────────
  // Checks each spending goal + global budget. Over limit = 0, under 50% = 100.
  static int _budgetScore(
    List<SpendingGoal> goals,
    List<Map<String, dynamic>> allTx,
    DateTime now,
    double monthlyBudget,
    double monthExpense,
    DateTime? Function(Map<String, dynamic>) parseDate,
    double Function(Map<String, dynamic>) amt,
  ) {
    final checks = <int>[];

    if (monthlyBudget > 0) {
      checks.add(_pctToScore(monthExpense / monthlyBudget));
    }

    for (final g in goals) {
      if (g.limitAmount <= 0) continue;
      final start = g.period == 'weekly'
          ? DateTime(now.year, now.month, now.day - now.weekday + 1)
          : DateTime(now.year, now.month, 1);

      final spent = allTx.where((t) {
        if (t['type'] != 'expense') return false;
        if (g.category != 'All' && t['category'] != g.category) return false;
        final d = parseDate(t);
        return d != null && !d.isBefore(start);
      }).fold(0.0, (s, t) => s + amt(t));

      checks.add(_pctToScore(spent / g.limitAmount));
    }

    if (checks.isEmpty) return 70; // no limits set — neutral
    return (checks.reduce((a, b) => a + b) / checks.length).round();
  }

  // Maps spent/limit ratio to a score. Below 50% = perfect, over 100% = zero.
  static int _pctToScore(double pct) {
    if (pct <= 0.50) return 100;
    if (pct <= 0.75) return 90;
    if (pct <= 0.90) return 70;
    if (pct <= 1.00) return 40;
    return 0;
  }

  // ── Component 3: Goal Progress ─────────────────────────────────────────────
  // Are savings goals on track? Compares actual progress vs expected timeline.
  static int _goalScore(List<SavingsGoal> goals, DateTime now) {
    if (goals.isEmpty) return 60;
    final active = goals.where((g) => g.savedAmount < g.targetAmount).toList();
    if (active.isEmpty) return 100;

    final scores = <int>[];
    for (final g in active) {
      final progress = (g.savedAmount / g.targetAmount).clamp(0.0, 1.0);
      if (g.targetDate != null) {
        final totalDays = g.targetDate!.difference(g.createdAt).inDays;
        final elapsedDays = now.difference(g.createdAt).inDays;
        final expected = totalDays > 0
            ? (elapsedDays / totalDays).clamp(0.0, 1.0)
            : 0.5;
        final ratio = expected > 0 ? progress / expected : progress;
        scores.add((ratio * 100).clamp(0, 100).round());
      } else {
        scores.add((progress * 100).clamp(0, 100).round());
      }
    }
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  // ── Component 4: Consistency ───────────────────────────────────────────────
  // How even is daily spending? One huge spike day vs steady = penalised.
  // Compares the worst single day to the average day over last 30 days.
  static int _consistencyScore(
    List<Map<String, dynamic>> allTx,
    DateTime? Function(Map<String, dynamic>) parseDate,
    double Function(Map<String, dynamic>) amt,
    DateTime now,
  ) {
    final cutoff = now.subtract(const Duration(days: 30));
    final dayMap = <int, double>{};

    for (final t in allTx) {
      if (t['type'] != 'expense') continue;
      final d = parseDate(t);
      if (d == null || d.isBefore(cutoff)) continue;
      final key = d.year * 10000 + d.month * 100 + d.day;
      dayMap[key] = (dayMap[key] ?? 0) + amt(t);
    }

    if (dayMap.length < 4) return 70;

    final amounts = dayMap.values.toList();
    final avg = amounts.reduce((a, b) => a + b) / amounts.length;
    final maxDay = amounts.reduce((a, b) => a > b ? a : b);

    if (avg <= 0) return 70;
    final ratio = maxDay / avg;
    if (ratio < 2.0) return 100;
    if (ratio < 3.0) return 80;
    if (ratio < 4.0) return 60;
    if (ratio < 5.0) return 40;
    return 20;
  }
}
