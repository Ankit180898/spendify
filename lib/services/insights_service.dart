import 'package:flutter/material.dart';
import 'package:spendify/model/savings_goal_model.dart';

enum InsightType { warning, positive, info }

class Insight {
  final String emoji;
  final String title;
  final String body;
  final InsightType type;

  const Insight({
    required this.emoji,
    required this.title,
    required this.body,
    required this.type,
  });

  Color get accentColor {
    switch (type) {
      case InsightType.warning:
        return const Color(0xFFF97316);
      case InsightType.positive:
        return const Color(0xFF22C55E);
      case InsightType.info:
        return const Color(0xFF6366F1);
    }
  }
}

class InsightsService {
  /// Computes a list of insights from raw data. No external calls, no state.
  static List<Insight> compute({
    required List<Map<String, dynamic>> allTransactions,
    required double monthlyBudget,
    required String sym,
    required List<SavingsGoal> savingsGoals,
  }) {
    final insights = <Insight>[];
    final now = DateTime.now();

    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    double amt(Map<String, dynamic> t) =>
        (t['amount'] as num?)?.toDouble() ?? 0.0;

    DateTime? parseDate(Map<String, dynamic> t) =>
        DateTime.tryParse(t['date'] ?? '');

    final thisMonthExp = allTransactions.where((t) {
      final d = parseDate(t);
      return d != null && !d.isBefore(thisMonthStart) && t['type'] == 'expense';
    }).toList();

    // Compare same number of days into last month — clamp to last month's actual length
    // e.g. March 31 → clamp to Feb 28, not Feb 31 (which overflows to March 3)
    final lastMonthDays = DateTime(now.year, now.month, 0).day;
    final clampedDay = now.day.clamp(1, lastMonthDays);
    final lastMonthSameDayEnd = DateTime(now.year, now.month - 1, clampedDay, 23, 59, 59);
    final lastMonthExp = allTransactions.where((t) {
      final d = parseDate(t);
      return d != null &&
          !d.isBefore(lastMonthStart) &&
          !d.isAfter(lastMonthSameDayEnd) &&
          t['type'] == 'expense';
    }).toList();

    final thisMonthInc = allTransactions.where((t) {
      final d = parseDate(t);
      return d != null && !d.isBefore(thisMonthStart) && t['type'] == 'income';
    }).toList();

    final thisSpent = thisMonthExp.fold(0.0, (s, t) => s + amt(t));
    final lastSpent = lastMonthExp.fold(0.0, (s, t) => s + amt(t));
    final thisIncome = thisMonthInc.fold(0.0, (s, t) => s + amt(t));

    // ── 1. Spending vs last month ──────────────────────────────────────────
    if (lastSpent > 0 && thisSpent > 0) {
      final pct = ((thisSpent - lastSpent) / lastSpent * 100).round();
      if (pct > 10) {
        insights.add(Insight(
          emoji: '📈',
          title: 'Spending up $pct%',
          body: 'You\'ve spent more this month than last. Consider reviewing your categories.',
          type: InsightType.warning,
        ));
      } else if (pct < -10) {
        insights.add(Insight(
          emoji: '📉',
          title: 'Spending down ${pct.abs()}%',
          body: 'Nice work — you\'re spending less than last month!',
          type: InsightType.positive,
        ));
      }
    }

    // ── 2. Top spending category ───────────────────────────────────────────
    if (thisMonthExp.isNotEmpty) {
      final catTotals = <String, double>{};
      for (final t in thisMonthExp) {
        final cat = (t['category'] as String?) ?? 'Others';
        catTotals[cat] = (catTotals[cat] ?? 0) + amt(t);
      }
      final top = catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      final pct = thisSpent > 0 ? (top.value / thisSpent * 100).round() : 0;
      insights.add(Insight(
        emoji: '🏆',
        title: '${top.key} leads spending',
        body: '$sym${_fmt(top.value)} this month ($pct% of total expenses).',
        type: InsightType.info,
      ));
    }

    // ── 3. Savings rate ────────────────────────────────────────────────────
    if (thisIncome > 0) {
      final rate = ((thisIncome - thisSpent) / thisIncome * 100).round();
      if (rate >= 20) {
        insights.add(Insight(
          emoji: '💰',
          title: 'Saving $rate% of income',
          body: 'Great discipline — you\'re keeping a healthy savings rate.',
          type: InsightType.positive,
        ));
      } else if (rate < 0) {
        insights.add(Insight(
          emoji: '⚠️',
          title: 'Spending more than earned',
          body: 'You\'ve spent ${rate.abs()}% more than your income this month.',
          type: InsightType.warning,
        ));
      } else {
        insights.add(Insight(
          emoji: '📊',
          title: 'Saving $rate% of income',
          body: 'Try to reach 20% savings rate for a healthier financial cushion.',
          type: InsightType.info,
        ));
      }
    }

    // ── 4. Budget projection ───────────────────────────────────────────────
    if (monthlyBudget > 0 && now.day > 3) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dailyAvg = thisSpent / now.day;
      final projected = dailyAvg * daysInMonth;
      if (projected > monthlyBudget * 1.05) {
        final over = projected - monthlyBudget;
        insights.add(Insight(
          emoji: '🚨',
          title: 'Projected overspend',
          body: 'At this pace you\'re on track to exceed your budget by $sym${_fmt(over)}.',
          type: InsightType.warning,
        ));
      } else if (projected < monthlyBudget * 0.85) {
        final under = monthlyBudget - projected;
        insights.add(Insight(
          emoji: '✅',
          title: 'On track with budget',
          body: 'You\'re projected to end the month $sym${_fmt(under)} under budget.',
          type: InsightType.positive,
        ));
      }
    }

    // ── 5. Transaction logging streak ─────────────────────────────────────
    if (allTransactions.isNotEmpty) {
      final sorted = allTransactions
          .map((t) => parseDate(t))
          .whereType<DateTime>()
          .toList()
        ..sort((a, b) => b.compareTo(a));
      final lastDate = sorted.first;
      final daysSince = now.difference(lastDate).inDays;
      if (daysSince == 0) {
        insights.add(const Insight(
          emoji: '🔥',
          title: 'Logged today',
          body: 'You\'re on top of your finances. Keep logging daily for best insights.',
          type: InsightType.positive,
        ));
      } else if (daysSince >= 5) {
        insights.add(Insight(
          emoji: '📝',
          title: '$daysSince days without a log',
          body: 'Quick reminder to log any recent transactions you may have missed.',
          type: InsightType.warning,
        ));
      }
    }

    // ── 6. Savings goal nudge ──────────────────────────────────────────────
    final activeGoals = savingsGoals
        .where((g) => g.savedAmount < g.targetAmount)
        .toList();

    for (final goal in activeGoals.take(1)) {
      final remaining = goal.targetAmount - goal.savedAmount;
      if (goal.targetDate != null) {
        final monthsLeft =
            (goal.targetDate!.difference(now).inDays / 30).ceil();
        if (monthsLeft > 0) {
          final needed = remaining / monthsLeft;
          insights.add(Insight(
            emoji: goal.emoji,
            title: '${goal.name} — $monthsLeft months left',
            body: 'Save $sym${_fmt(needed)}/month to hit your goal on time.',
            type: monthsLeft <= 2 ? InsightType.warning : InsightType.info,
          ));
        }
      } else {
        final pct = (goal.savedAmount / goal.targetAmount * 100).round();
        insights.add(Insight(
          emoji: goal.emoji,
          title: '${goal.name} at $pct%',
          body: '$sym${_fmt(remaining)} left to reach your goal.',
          type: InsightType.info,
        ));
      }
    }

    // ── 7. No data fallback ────────────────────────────────────────────────
    if (insights.isEmpty) {
      insights.add(const Insight(
        emoji: '👋',
        title: 'Start logging transactions',
        body: 'Once you log a few transactions, personalised insights will appear here.',
        type: InsightType.info,
      ));
    }

    // Warnings first, then positives, then info
    insights.sort((a, b) {
      const order = {
        InsightType.warning: 0,
        InsightType.positive: 1,
        InsightType.info: 2,
      };
      return order[a.type]!.compareTo(order[b.type]!);
    });

    return insights;
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
