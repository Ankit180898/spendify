import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/model/savings_goal_model.dart';

enum InsightType { warning, positive, info }

class Insight {
  /// Phosphor icon data (any style).
  final Object icon;
  final String title;
  final String body;
  final InsightType type;

  /// Optional short stat shown prominently on the card (e.g. "₹450/day")
  final String? stat;

  /// Optional progress value 0.0–1.0 for a mini bar in the detail sheet
  final double? progress;

  const Insight({
    required this.icon,
    required this.title,
    required this.body,
    required this.type,
    this.stat,
    this.progress,
  });

  Color get accentColor {
    switch (type) {
      case InsightType.warning:
        return AppColor.warning;
      case InsightType.positive:
        return AppColor.income;
      case InsightType.info:
        return AppColor.primary;
    }
  }
}

/// Pure, synchronous insight engine.
///
/// Ground rules that keep the numbers honest:
/// - Only transactions dated up to today count (future-dated entries are ignored).
/// - Month-over-month comparisons use the same number of days, and only run
///   when last month was actually tracked from (near) its start.
/// - Budget projections separate large one-offs (rent, bills) from day-to-day
///   spending, so a rent payment on the 1st doesn't project a 10× overspend.
/// - Nothing fires on too little data (early in the month, or a handful of entries).
class InsightsService {
  static const int maxInsights = 5;

  /// Categories that behave like fixed monthly costs rather than daily spend.
  static const _fixedCategories = {
    'bills & fees',
    'bills',
    'rent',
    'subscriptions',
    'investments',
    'emi',
    'loan',
    'insurance',
    'education',
  };

  static List<Insight> compute({
    required List<Map<String, dynamic>> allTransactions,
    required double monthlyBudget,
    required String sym,
    required List<SavingsGoal> savingsGoals,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = today.add(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;
    final daysLeft = daysInMonth - dayOfMonth + 1; // including today

    double amt(Map<String, dynamic> t) => (t['amount'] as num?)?.toDouble() ?? 0.0;
    DateTime? dateOf(Map<String, dynamic> t) {
      final raw = t['date'];
      final d = raw is String ? DateTime.tryParse(raw) : null;
      return d?.toLocal();
    }

    // Only past/present entries
    final txs = allTransactions.where((t) {
      final d = dateOf(t);
      return d != null && d.isBefore(endOfToday);
    }).toList();

    if (txs.isEmpty) {
      return [
        Insight(
          icon: PhosphorIconsDuotone.sparkle,
          title: 'Log a few transactions to unlock insights',
          body: 'Once you\'ve logged some income and expenses, you\'ll see spending trends, budget pace and saving rate here.',
          type: InsightType.info,
        ),
      ];
    }

    final firstDate = txs.map(dateOf).whereType<DateTime>().reduce((a, b) => a.isBefore(b) ? a : b);
    final trackingDays = today.difference(DateTime(firstDate.year, firstDate.month, firstDate.day)).inDays + 1;

    bool inRange(Map<String, dynamic> t, DateTime from, DateTime to) {
      final d = dateOf(t);
      return d != null && !d.isBefore(from) && d.isBefore(to);
    }

    final monthExp = txs.where((t) => t['type'] == 'expense' && inRange(t, monthStart, endOfToday)).toList();
    final monthInc = txs.where((t) => t['type'] == 'income' && inRange(t, monthStart, endOfToday)).toList();
    final spent = monthExp.fold(0.0, (s, t) => s + amt(t));
    final earned = monthInc.fold(0.0, (s, t) => s + amt(t));

    // Same-length window last month (e.g. 1–4 Sep vs 1–4 Oct)
    final lastMonthLen = DateTime(now.year, now.month, 0).day;
    final lastWindowEnd = DateTime(now.year, now.month - 1, dayOfMonth.clamp(1, lastMonthLen))
        .add(const Duration(days: 1));
    final lastExp = txs.where((t) => t['type'] == 'expense' && inRange(t, lastMonthStart, lastWindowEnd)).toList();
    final lastSpent = lastExp.fold(0.0, (s, t) => s + amt(t));
    // Last month only counts if tracking began within its first 3 days
    final lastMonthTracked = !firstDate.isAfter(lastMonthStart.add(const Duration(days: 3)));

    final warnings = <Insight>[];
    final positives = <Insight>[];
    final infos = <Insight>[];

    // ── 1. Budget pace ─────────────────────────────────────────────────────
    if (monthlyBudget > 0 && monthExp.isNotEmpty) {
      final remaining = monthlyBudget - spent;
      final usedPct = (spent / monthlyBudget * 100).round();
      final monthPct = (dayOfMonth / daysInMonth * 100).round();

      if (remaining < 0) {
        warnings.add(Insight(
          icon: PhosphorIconsDuotone.warningCircle,
          title: 'Over budget by $sym${_fmt(-remaining)}',
          body: 'You\'ve spent $sym${_fmt(spent)} against a $sym${_fmt(monthlyBudget)} budget with $daysLeft ${daysLeft == 1 ? 'day' : 'days'} still to go this month.',
          type: InsightType.warning,
          stat: '$usedPct% used',
          progress: 1,
        ));
      } else if (dayOfMonth >= 5) {
        // Separate fixed/one-off costs from day-to-day spending
        final oneOffThreshold = monthlyBudget * 0.2;
        double fixed = 0, variable = 0;
        for (final t in monthExp) {
          final cat = ((t['category'] as String?) ?? '').toLowerCase();
          if (_fixedCategories.contains(cat) || amt(t) >= oneOffThreshold) {
            fixed += amt(t);
          } else {
            variable += amt(t);
          }
        }
        final dailyVariable = variable / dayOfMonth;
        final projected = fixed + dailyVariable * daysInMonth;
        final safePerDay = remaining / daysLeft;

        if (projected > monthlyBudget * 1.05) {
          warnings.add(Insight(
            icon: PhosphorIconsDuotone.trendUp,
            title: 'On pace to overspend by $sym${_fmt(projected - monthlyBudget)}',
            body: 'Day-to-day spending is averaging $sym${_fmt(dailyVariable)}/day. To stay within budget, keep it under $sym${_fmt(safePerDay)}/day for the rest of the month.',
            type: InsightType.warning,
            stat: '$sym${_fmt(safePerDay)}/day',
            progress: (spent / monthlyBudget).clamp(0.0, 1.0),
          ));
        } else if (projected < monthlyBudget * 0.9 && dayOfMonth >= 10) {
          positives.add(Insight(
            icon: PhosphorIconsDuotone.shieldCheck,
            title: 'On track to finish $sym${_fmt(monthlyBudget - projected)} under budget',
            body: '$usedPct% of your budget used, $monthPct% of the month gone. You can spend about $sym${_fmt(safePerDay)}/day and still stay on budget.',
            type: InsightType.positive,
            stat: '$usedPct% used',
            progress: (spent / monthlyBudget).clamp(0.0, 1.0),
          ));
        }
      }
    }

    // ── 2. Spending vs same point last month ───────────────────────────────
    if (lastMonthTracked && lastSpent > 0 && spent > 0 && dayOfMonth >= 5) {
      final pct = ((spent - lastSpent) / lastSpent * 100).round();
      if (pct >= 15) {
        warnings.add(Insight(
          icon: PhosphorIconsDuotone.arrowUpRight,
          title: 'Spending is up $pct% on last month',
          body: '$sym${_fmt(spent)} in the first $dayOfMonth days, vs $sym${_fmt(lastSpent)} over the same days last month.',
          type: InsightType.warning,
          stat: '+$pct%',
        ));
      } else if (pct <= -15) {
        positives.add(Insight(
          icon: PhosphorIconsDuotone.arrowDownRight,
          title: 'Spending is down ${-pct}% on last month',
          body: '$sym${_fmt(spent)} in the first $dayOfMonth days, vs $sym${_fmt(lastSpent)} over the same days last month — $sym${_fmt(lastSpent - spent)} saved.',
          type: InsightType.positive,
          stat: '${-pct}% less',
        ));
      }
    }

    // ── 3. Top category ────────────────────────────────────────────────────
    if (monthExp.length >= 3 && spent > 0) {
      final byCat = <String, double>{};
      for (final t in monthExp) {
        final cat = (t['category'] as String?)?.trim();
        final key = (cat == null || cat.isEmpty) ? 'Uncategorised' : cat;
        byCat[key] = (byCat[key] ?? 0) + amt(t);
      }
      if (byCat.length >= 2) {
        final top = byCat.entries.reduce((a, b) => a.value >= b.value ? a : b);
        final share = (top.value / spent * 100).round();
        var change = '';
        if (lastMonthTracked) {
          final lastCat = lastExp
              .where((t) => ((t['category'] as String?)?.trim() ?? '') == top.key)
              .fold(0.0, (s, t) => s + amt(t));
          if (lastCat > 0) {
            final c = ((top.value - lastCat) / lastCat * 100).round();
            if (c.abs() >= 10) {
              change = c > 0 ? ' That\'s up $c% on the same days last month.' : ' That\'s down ${-c}% on the same days last month.';
            }
          }
        }
        infos.add(Insight(
          icon: PhosphorIconsDuotone.chartPieSlice,
          title: '${top.key} is $share% of your spending',
          body: '$sym${_fmt(top.value)} of $sym${_fmt(spent)} this month went to ${top.key}.$change',
          type: InsightType.info,
          stat: '$sym${_fmt(top.value)}',
          progress: top.value / spent,
        ));
      }
    }

    // ── 4. Saving rate ─────────────────────────────────────────────────────
    if (earned > 0) {
      final saved = earned - spent;
      final rate = (saved / earned * 100).round();
      if (saved < 0 && dayOfMonth >= 7) {
        warnings.add(Insight(
          icon: PhosphorIconsDuotone.scales,
          title: 'Spent $sym${_fmt(-saved)} more than you earned',
          body: '$sym${_fmt(spent)} out vs $sym${_fmt(earned)} in this month. If more income is due, log it to keep this accurate.',
          type: InsightType.warning,
          stat: '−$sym${_fmt(-saved)}',
        ));
      } else if (rate >= 20 && spent > 0) {
        positives.add(Insight(
          icon: PhosphorIconsDuotone.piggyBank,
          title: 'Keeping $rate% of your income so far',
          body: '$sym${_fmt(saved)} of the $sym${_fmt(earned)} you earned this month is still unspent. Moving some into a savings goal locks it in.',
          type: InsightType.positive,
          stat: '$rate% kept',
          progress: (rate / 100).clamp(0.0, 1.0),
        ));
      }
    }

    // ── 5. Logging gap ─────────────────────────────────────────────────────
    final lastLogged = allTransactions
        .map((t) {
          final raw = t['created_at'] ?? t['date'];
          return raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
        })
        .whereType<DateTime>()
        .where((d) => d.isBefore(endOfToday))
        .fold<DateTime?>(null, (m, d) => m == null || d.isAfter(m) ? d : m);
    if (lastLogged != null) {
      final gap = today.difference(DateTime(lastLogged.year, lastLogged.month, lastLogged.day)).inDays;
      if (gap >= 4) {
        warnings.add(Insight(
          icon: PhosphorIconsDuotone.pencilSimpleLine,
          title: 'Nothing logged for $gap days',
          body: 'Insights are only as good as your entries. Catch up on anything you\'ve spent since ${_shortDate(lastLogged)} — it only takes a minute.',
          type: InsightType.warning,
          stat: '$gap days',
        ));
      }
    }

    // ── 6. No-spend days (only days you were actually tracking) ───────────
    final countFrom = firstDate.isAfter(monthStart)
        ? DateTime(firstDate.year, firstDate.month, firstDate.day)
        : monthStart;
    final pastDays = today.difference(countFrom).inDays; // excludes today
    if (pastDays >= 7 && trackingDays >= 7) {
      final spendDays = monthExp
          .map(dateOf)
          .whereType<DateTime>()
          .map((d) => DateTime(d.year, d.month, d.day))
          .where((d) => d.isBefore(today) && !d.isBefore(countFrom))
          .toSet()
          .length;
      final noSpend = pastDays - spendDays;
      if (noSpend >= 3) {
        positives.add(Insight(
          icon: PhosphorIconsDuotone.leaf,
          title: '$noSpend no-spend ${noSpend == 1 ? 'day' : 'days'} this month',
          body: 'Out of the last $pastDays days, $noSpend had no expenses at all. Quiet days add up.',
          type: InsightType.positive,
          stat: '$noSpend days',
        ));
      }
    }

    // ── 7. Biggest single expense ──────────────────────────────────────────
    if (monthExp.length >= 4) {
      final biggest = monthExp.reduce((a, b) => amt(a) >= amt(b) ? a : b);
      final big = amt(biggest);
      final othersAvg = (spent - big) / (monthExp.length - 1);
      if (othersAvg > 0 && big >= othersAvg * 3 && big >= 500) {
        final d = dateOf(biggest);
        final label = (biggest['description'] as String?)?.trim().isNotEmpty == true
            ? biggest['description'] as String
            : (biggest['category'] as String?) ?? 'One expense';
        infos.add(Insight(
          icon: PhosphorIconsDuotone.receipt,
          title: 'Biggest expense: $label',
          body: '$sym${_fmt(big)}${d != null ? ' on ${_shortDate(d)}' : ''} — ${(big / spent * 100).round()}% of this month\'s spending and ${(big / othersAvg).toStringAsFixed(1)}× your typical expense.',
          type: InsightType.info,
          stat: '$sym${_fmt(big)}',
        ));
      }
    }

    // ── 8. Weekends vs weekdays (per day, so 2 vs 5 days is fair) ─────────
    if (monthExp.length >= 8 && dayOfMonth >= 10) {
      var weekendDays = 0, weekdayDays = 0;
      for (var d = monthStart; d.isBefore(endOfToday); d = d.add(const Duration(days: 1))) {
        d.weekday >= 6 ? weekendDays++ : weekdayDays++;
      }
      final weekendSpend = monthExp
          .where((t) => (dateOf(t)?.weekday ?? 1) >= 6)
          .fold(0.0, (s, t) => s + amt(t));
      final weekdaySpend = spent - weekendSpend;
      if (weekendDays > 0 && weekdayDays > 0 && weekdaySpend > 0) {
        final perWeekend = weekendSpend / weekendDays;
        final perWeekday = weekdaySpend / weekdayDays;
        final ratio = perWeekend / perWeekday;
        if (ratio >= 1.5) {
          infos.add(Insight(
            icon: PhosphorIconsDuotone.calendarStar,
            title: 'Weekends cost ${ratio.toStringAsFixed(1)}× more per day',
            body: 'About $sym${_fmt(perWeekend)} per weekend day vs $sym${_fmt(perWeekday)} on weekdays this month.',
            type: InsightType.info,
            stat: '${ratio.toStringAsFixed(1)}×',
          ));
        }
      }
    }

    // ── 9. Savings goals with deadlines ───────────────────────────────────
    final dated = savingsGoals
        .where((g) => g.targetDate != null && g.savedAmount < g.targetAmount && g.targetAmount > 0)
        .toList()
      ..sort((a, b) => a.targetDate!.compareTo(b.targetDate!));
    for (final g in dated.take(2)) {
      final remaining = g.targetAmount - g.savedAmount;
      final pct = g.savedAmount / g.targetAmount;
      final deadline = DateTime(g.targetDate!.year, g.targetDate!.month, g.targetDate!.day);
      final days = deadline.difference(today).inDays;
      if (days < 0) {
        warnings.add(Insight(
          icon: PhosphorIconsDuotone.target,
          title: '${g.name} passed its deadline',
          body: '${(pct * 100).round()}% funded with $sym${_fmt(remaining)} still to go. Pick a new date or top it up to finish.',
          type: InsightType.warning,
          stat: '${(pct * 100).round()}%',
          progress: pct,
        ));
      } else if (days <= 31) {
        final perWeek = remaining / ((days / 7).ceil().clamp(1, 5));
        warnings.add(Insight(
          icon: PhosphorIconsDuotone.target,
          title: '${g.name}: $sym${_fmt(remaining)} to go in $days ${days == 1 ? 'day' : 'days'}',
          body: 'Put aside about $sym${_fmt(perWeek)} a week to reach it by ${_shortDate(deadline)}.',
          type: InsightType.warning,
          stat: '$sym${_fmt(perWeek)}/wk',
          progress: pct,
        ));
      } else {
        final months = days / 30.44;
        infos.add(Insight(
          icon: PhosphorIconsDuotone.target,
          title: '${g.name}: save $sym${_fmt(remaining / months)} a month',
          body: '${(pct * 100).round()}% funded. That pace gets you the remaining $sym${_fmt(remaining)} by ${_shortDate(deadline)}.',
          type: InsightType.info,
          stat: '${(pct * 100).round()}%',
          progress: pct,
        ));
      }
    }

    final all = [...warnings, ...positives, ...infos];

    if (all.isEmpty) {
      all.add(Insight(
        icon: monthExp.isEmpty ? PhosphorIconsDuotone.sun : PhosphorIconsDuotone.checkCircle,
        title: monthExp.isEmpty ? 'A fresh month' : 'Nothing unusual this month',
        body: monthExp.isEmpty
            ? 'No expenses logged yet this month. Insights appear as soon as there\'s something to compare.'
            : 'Your spending looks steady. Keep logging and we\'ll flag anything worth a look.',
        type: monthExp.isEmpty ? InsightType.info : InsightType.positive,
      ));
    }

    return all.take(maxInsights).toList();
  }

  static String _fmt(double v) {
    final a = v.abs();
    if (a >= 10000000) return '${(a / 10000000).toStringAsFixed(1)}Cr';
    if (a >= 100000) return '${(a / 100000).toStringAsFixed(1)}L';
    if (a >= 1000) return '${(a / 1000).toStringAsFixed(1)}K';
    return a.toStringAsFixed(0);
  }

  static String _shortDate(DateTime d) =>
      '${d.day} ${const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month]}';
}
