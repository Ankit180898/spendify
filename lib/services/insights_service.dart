import 'package:flutter/material.dart';
import 'package:spendify/model/savings_goal_model.dart';

enum InsightType { warning, positive, info }

class Insight {
  final String emoji;
  final String title;
  final String body;
  final InsightType type;
  /// Optional short stat shown prominently on the card (e.g. "₹450/day")
  final String? stat;
  /// Optional progress value 0.0–1.0 for mini bar on card
  final double? progress;

  const Insight({
    required this.emoji,
    required this.title,
    required this.body,
    required this.type,
    this.stat,
    this.progress,
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
    final lastMonthSameDayEnd =
        DateTime(now.year, now.month - 1, clampedDay, 23, 59, 59);
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
          title: 'Spending up $pct% vs last month',
          body: 'You\'ve spent $sym${_fmt(thisSpent)} so far this month — $sym${_fmt(thisSpent - lastSpent)} more than at the same point last month. Check which category drove the increase.',
          type: InsightType.warning,
          stat: '+$pct%',
        ));
      } else if (pct < -10) {
        insights.add(Insight(
          emoji: '📉',
          title: 'Spending down ${pct.abs()}% vs last month',
          body: 'You\'ve spent $sym${_fmt(thisSpent)} this month — $sym${_fmt(lastSpent - thisSpent)} less than the same point last month. Great discipline!',
          type: InsightType.positive,
          stat: '${pct.abs()}% less',
        ));
      }
    }

    // ── 2. Top spending category with MoM comparison ───────────────────────
    if (thisMonthExp.isNotEmpty) {
      final catTotals = <String, double>{};
      for (final t in thisMonthExp) {
        final cat = (t['category'] as String?) ?? 'Others';
        catTotals[cat] = (catTotals[cat] ?? 0) + amt(t);
      }
      final top = catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      final pct = thisSpent > 0 ? (top.value / thisSpent * 100).round() : 0;

      // Check same category last month
      final lastCatSpend = lastMonthExp
          .where((t) => (t['category'] as String?) == top.key)
          .fold(0.0, (s, t) => s + amt(t));
      final catChange = lastCatSpend > 0
          ? ((top.value - lastCatSpend) / lastCatSpend * 100).round()
          : null;
      final changeStr = catChange != null
          ? (catChange > 0 ? ', up $catChange% vs last month' : ', down ${catChange.abs()}% vs last month')
          : '';

      insights.add(Insight(
        emoji: '🏆',
        title: '${top.key} is your top spend',
        body: '$sym${_fmt(top.value)} on ${top.key} this month — $pct% of your total expenses$changeStr.',
        type: catChange != null && catChange > 25 ? InsightType.warning : InsightType.info,
        stat: '$pct% of spend',
        progress: thisSpent > 0 ? (top.value / thisSpent).clamp(0.0, 1.0) : null,
      ));
    }

    // ── 3. Savings rate ────────────────────────────────────────────────────
    if (thisIncome > 0) {
      final rate = ((thisIncome - thisSpent) / thisIncome * 100).round();
      final savedAmt = thisIncome - thisSpent;
      if (rate >= 20) {
        insights.add(Insight(
          emoji: '💰',
          title: 'Saving $rate% of income',
          body: 'You\'ve saved $sym${_fmt(savedAmt.abs())} of your $sym${_fmt(thisIncome)} income this month. The 50/30/20 rule recommends at least 20% — you\'re nailing it.',
          type: InsightType.positive,
          stat: '$rate% saved',
          progress: (rate / 100).clamp(0.0, 1.0),
        ));
      } else if (rate < 0) {
        insights.add(Insight(
          emoji: '⚠️',
          title: 'Spending more than you earned',
          body: 'You\'ve spent $sym${_fmt(savedAmt.abs())} more than your income of $sym${_fmt(thisIncome)} this month. Try reducing discretionary spending.',
          type: InsightType.warning,
          stat: '${rate.abs()}% over',
        ));
      } else {
        insights.add(Insight(
          emoji: '📊',
          title: 'Saving $rate% of income',
          body: 'You\'re saving $sym${_fmt(savedAmt)} of $sym${_fmt(thisIncome)} earned. Aim for 20% ($sym${_fmt(thisIncome * 0.2)}/month) for a healthier cushion.',
          type: InsightType.info,
          stat: '$rate% saved',
          progress: (rate / 20).clamp(0.0, 1.0),
        ));
      }
    }

    // ── 4. Budget projection ───────────────────────────────────────────────
    if (monthlyBudget > 0 && now.day > 3) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dailyAvg = thisSpent / now.day;
      final projected = dailyAvg * daysInMonth;
      final budgetUsedPct = (thisSpent / monthlyBudget * 100).round();
      final monthPct = (now.day / daysInMonth * 100).round();

      if (projected > monthlyBudget * 1.05) {
        final over = projected - monthlyBudget;
        insights.add(Insight(
          emoji: '🚨',
          title: 'On track to overspend',
          body: 'You\'ve used $budgetUsedPct% of your budget in $monthPct% of the month. At $sym${_fmt(dailyAvg)}/day you\'ll exceed your budget by $sym${_fmt(over)}. Aim for $sym${_fmt((monthlyBudget - thisSpent) / (daysInMonth - now.day).clamp(1, 31))}/day from now.',
          type: InsightType.warning,
          stat: '$budgetUsedPct% used',
          progress: (thisSpent / monthlyBudget).clamp(0.0, 1.0),
        ));
      } else if (projected < monthlyBudget * 0.85) {
        final under = monthlyBudget - projected;
        insights.add(Insight(
          emoji: '✅',
          title: 'Well within budget',
          body: 'Only $budgetUsedPct% of budget used in $monthPct% of the month. You\'re projected to end $sym${_fmt(under)} under budget. Great pacing!',
          type: InsightType.positive,
          stat: '$budgetUsedPct% of budget',
          progress: (thisSpent / monthlyBudget).clamp(0.0, 1.0),
        ));
      }
    }

    // ── 5. Daily spending pace ─────────────────────────────────────────────
    if (thisMonthExp.isNotEmpty && now.day > 3) {
      final dailyAvg = thisSpent / now.day;
      final lastMonthDailyAvg = lastSpent > 0 ? lastSpent / now.day : 0.0;
      if (lastMonthDailyAvg > 0) {
        final paceChange = ((dailyAvg - lastMonthDailyAvg) / lastMonthDailyAvg * 100).round();
        if (paceChange.abs() >= 20) {
          insights.add(Insight(
            emoji: paceChange > 0 ? '⚡' : '🐢',
            title: paceChange > 0
                ? 'Spending $paceChange% faster this month'
                : 'Spending ${paceChange.abs()}% slower this month',
            body: 'Daily average: $sym${_fmt(dailyAvg)}/day this month vs $sym${_fmt(lastMonthDailyAvg)}/day at the same point last month.',
            type: paceChange > 30 ? InsightType.warning : InsightType.info,
            stat: '$sym${_fmt(dailyAvg)}/day',
          ));
        }
      }
    }

    // ── 6. Transaction logging streak ─────────────────────────────────────
    if (allTransactions.isNotEmpty) {
      final dates = allTransactions
          .map((t) => parseDate(t))
          .whereType<DateTime>()
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final today = DateTime(now.year, now.month, now.day);
      int streak = 0;
      for (int i = 0; i < dates.length; i++) {
        final expected = today.subtract(Duration(days: i));
        if (dates[i] == expected) {
          streak++;
        } else {
          break;
        }
      }

      // No-spend days this month (exclude today — day isn't over yet)
      final daysInMonthSoFar = (now.day - 1).clamp(0, 31);
      final daysWithSpend = thisMonthExp
          .map((t) => parseDate(t))
          .whereType<DateTime>()
          .map((d) => DateTime(d.year, d.month, d.day))
          .where((d) => d != today) // exclude today to match daysInMonthSoFar
          .toSet()
          .length;
      final noSpendDays = daysInMonthSoFar - daysWithSpend;

      if (streak >= 3) {
        insights.add(Insight(
          emoji: '🔥',
          title: '$streak-day logging streak',
          body: 'You\'ve logged transactions for $streak days in a row. Consistent tracking gives you the most accurate insights.',
          type: InsightType.positive,
          stat: '$streak days',
        ));
      } else if (noSpendDays >= 3) {
        insights.add(Insight(
          emoji: '🌿',
          title: '$noSpendDays no-spend days this month',
          body: 'You had $noSpendDays days with zero spending so far this month. Every no-spend day adds to your savings.',
          type: InsightType.positive,
          stat: '$noSpendDays days',
        ));
      } else {
        final daysSince = now.difference(dates.first).inDays;
        if (daysSince >= 5) {
          insights.add(Insight(
            emoji: '📝',
            title: '$daysSince days without logging',
            body: 'You haven\'t logged a transaction in $daysSince days. Missing entries can make your insights less accurate.',
            type: InsightType.warning,
            stat: '$daysSince days gap',
          ));
        }
      }
    }

    // ── 7. Savings goal nudge ──────────────────────────────────────────────
    final activeGoals =
        savingsGoals.where((g) => g.savedAmount < g.targetAmount).toList();

    for (final goal in activeGoals.take(2)) {
      final remaining = goal.targetAmount - goal.savedAmount;
      final goalPct = (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
      if (goal.targetDate != null) {
        final monthsLeft = ((goal.targetDate!.year - now.year) * 12 +
                goal.targetDate!.month -
                now.month)
            .clamp(1, 999);
        if (monthsLeft > 0) {
          final needed = remaining / monthsLeft;
          insights.add(Insight(
            emoji: goal.emoji,
            title: '${goal.name} — $monthsLeft mo left',
            body: '${(goalPct * 100).round()}% funded. Save $sym${_fmt(needed)}/month to hit your goal on time. You need $sym${_fmt(remaining)} more.',
            type: monthsLeft <= 2 ? InsightType.warning : InsightType.info,
            stat: '$sym${_fmt(needed)}/mo needed',
            progress: goalPct,
          ));
        }
      } else {
        final pct = (goal.savedAmount / goal.targetAmount * 100).round();
        insights.add(Insight(
          emoji: goal.emoji,
          title: '${goal.name} at $pct%',
          body: '$sym${_fmt(goal.savedAmount)} of $sym${_fmt(goal.targetAmount)} saved. Just $sym${_fmt(remaining)} more to reach your goal.',
          type: InsightType.info,
          stat: '$pct% funded',
          progress: goalPct,
        ));
      }
    }

    // ── 8. Largest single transaction this month ───────────────────────────
    if (thisMonthExp.isNotEmpty) {
      final biggest = thisMonthExp.reduce((a, b) => amt(a) > amt(b) ? a : b);
      final bigAmt = amt(biggest);
      final avgTx = thisSpent / thisMonthExp.length;
      if (bigAmt > avgTx * 2.5 && bigAmt > 500) {
        final d = parseDate(biggest);
        final dateStr = d != null
            ? '${_weekday(d.weekday)}, ${d.day} ${_month(d.month)}'
            : 'this month';
        insights.add(Insight(
          emoji: '👀',
          title: 'Biggest spend: $sym${_fmt(bigAmt)}',
          body: '${biggest['description'] ?? biggest['category'] ?? 'A transaction'} on $dateStr was your largest expense — ${((bigAmt / thisSpent) * 100).round()}% of total monthly spend.',
          type: InsightType.info,
          stat: '$sym${_fmt(bigAmt)}',
        ));
      }
    }

    // ── 9. Weekend vs weekday spending ────────────────────────────────────
    if (thisMonthExp.length >= 5) {
      final weekendSpend = thisMonthExp
          .where((t) => [6, 7].contains(parseDate(t)?.weekday))
          .fold(0.0, (s, t) => s + amt(t));
      final weekdaySpend = thisSpent - weekendSpend;
      final weekendPct = thisSpent > 0 ? (weekendSpend / thisSpent * 100).round() : 0;
      if (weekendPct > 50) {
        insights.add(Insight(
          emoji: '🎉',
          title: '$weekendPct% of spending on weekends',
          body: 'You spend $sym${_fmt(weekendSpend)} on weekends vs $sym${_fmt(weekdaySpend)} on weekdays. Weekend outings and dining tend to add up fast.',
          type: InsightType.info,
          stat: '$weekendPct% weekends',
          progress: weekendPct / 100,
        ));
      }
    }

    // ── 10. No data fallback ───────────────────────────────────────────────
    if (insights.isEmpty) {
      insights.add(const Insight(
        emoji: '👋',
        title: 'Start logging transactions',
        body: 'Once you log a few transactions, personalised insights will appear here — spending trends, budget pace, saving rate and more.',
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

  static String _weekday(int w) => const ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w];
  static String _month(int m) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}
