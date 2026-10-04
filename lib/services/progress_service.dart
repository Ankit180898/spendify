import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserProgress — streaks, XP, levels and badges derived from logged transactions.
//
// Everything rewards *logging*, never spending: an expense and an income earn
// the same XP, and XP per day is capped so bulk entry can't be farmed.
// ─────────────────────────────────────────────────────────────────────────────

class Achievement {
  final String id;
  final String title;
  final String description;
  final Object icon; // Phosphor icon data (any style)
  final Color color;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
  });
}

class UserProgress {
  final int xp;
  final int level;
  final String levelTitle;
  final int levelStartXp;
  final int nextLevelXp;
  final int streak;
  final int bestStreak;
  final bool loggedToday;
  final int totalLogged;

  /// Mon→Sun of the current week; true when at least one entry was logged.
  final List<bool> weekDays;
  final List<Achievement> badges;

  const UserProgress({
    required this.xp,
    required this.level,
    required this.levelTitle,
    required this.levelStartXp,
    required this.nextLevelXp,
    required this.streak,
    required this.bestStreak,
    required this.loggedToday,
    required this.totalLogged,
    required this.weekDays,
    required this.badges,
  });

  double get levelProgress =>
      ((xp - levelStartXp) / (nextLevelXp - levelStartXp)).clamp(0.0, 1.0);

  int get unlockedCount => badges.where((b) => b.unlocked).length;
}

class ProgressService {
  ProgressService._();

  static const int xpPerEntry = 10;
  static const int maxEntriesPerDay = 5;
  static const int dailyBonus = 15;

  static const List<String> _titles = [
    'Rookie Tracker',
    'Penny Watcher',
    'Budget Builder',
    'Money Manager',
    'Finance Pro',
    'Wealth Wizard',
  ];

  /// XP needed to reach [level] (level 1 starts at 0): 0, 100, 300, 600, 1000…
  static int xpForLevel(int level) => 50 * level * (level - 1);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The day an entry was *logged*. Prefers created_at so back-dated or
  /// SMS-imported transactions don't inflate the streak.
  static DateTime? _loggedDay(Map<String, dynamic> t) {
    final raw = t['created_at'] ?? t['date'];
    final d = raw is String ? DateTime.tryParse(raw) : null;
    return d == null ? null : _day(d.toLocal());
  }

  static UserProgress compute({
    required List<Map<String, dynamic>> transactions,
    double monthlyBudget = 0,
  }) {
    final today = _day(DateTime.now());

    // Entries per logged day
    final perDay = <DateTime, int>{};
    for (final t in transactions) {
      final d = _loggedDay(t);
      if (d == null) continue;
      perDay[d] = (perDay[d] ?? 0) + 1;
    }

    // XP
    var xp = 0;
    for (final n in perDay.values) {
      final capped = n > maxEntriesPerDay ? maxEntriesPerDay : n;
      xp += capped * xpPerEntry + dailyBonus;
    }

    // Level
    var level = 1;
    while (xp >= xpForLevel(level + 1)) {
      level++;
    }
    final title = _titles[(level - 1).clamp(0, _titles.length - 1)];

    // Current streak — still alive if yesterday was logged but today isn't yet
    final loggedToday = perDay.containsKey(today);
    var cursor = loggedToday ? today : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (perDay.containsKey(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Best streak ever
    final days = perDay.keys.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final d in days) {
      run = (prev != null && d.difference(prev).inDays == 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }

    // This week, Monday first
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final week = List.generate(
      7,
      (i) => perDay.containsKey(monday.add(Duration(days: i))),
    );

    final total = transactions.length;
    final hasIncome = transactions.any((t) => t['type'] == 'income');

    // Budget kept: last full month's spend stayed within the budget
    var budgetKept = false;
    if (monthlyBudget > 0) {
      final lastStart = DateTime(today.year, today.month - 1, 1);
      final thisStart = DateTime(today.year, today.month, 1);
      final lastMonth = transactions.where((t) {
        final d = DateTime.tryParse(t['date'] ?? '');
        return d != null && !d.isBefore(lastStart) && d.isBefore(thisStart);
      }).toList();
      final spent = lastMonth
          .where((t) => t['type'] == 'expense')
          .fold(0.0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));
      budgetKept = lastMonth.isNotEmpty && spent <= monthlyBudget;
    }

    final badges = [
      Achievement(
        id: 'first_step',
        title: 'First Step',
        description: 'Log your first transaction',
        icon: PhosphorIconsDuotone.plant,
        color: AppColor.income,
        unlocked: total >= 1,
      ),
      Achievement(
        id: 'income_in',
        title: 'Payday',
        description: 'Log your first income',
        icon: PhosphorIconsDuotone.handCoins,
        color: AppColor.income,
        unlocked: hasIncome,
      ),
      Achievement(
        id: 'streak_3',
        title: 'On a Roll',
        description: 'Log 3 days in a row',
        icon: PhosphorIconsDuotone.flame,
        color: AppColor.warning,
        unlocked: best >= 3,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Week Warrior',
        description: 'Log 7 days in a row',
        icon: PhosphorIconsDuotone.fire,
        color: AppColor.expense,
        unlocked: best >= 7,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Habit Hero',
        description: 'Log 30 days in a row',
        icon: PhosphorIconsDuotone.crown,
        color: AppColor.warning,
        unlocked: best >= 30,
      ),
      Achievement(
        id: 'logged_50',
        title: 'Half Century',
        description: 'Log 50 transactions',
        icon: PhosphorIconsDuotone.medal,
        color: AppColor.primary,
        unlocked: total >= 50,
      ),
      Achievement(
        id: 'logged_100',
        title: 'Centurion',
        description: 'Log 100 transactions',
        icon: PhosphorIconsDuotone.trophy,
        color: AppColor.primary,
        unlocked: total >= 100,
      ),
      Achievement(
        id: 'budget_kept',
        title: 'Budget Keeper',
        description: 'Finish a month within budget',
        icon: PhosphorIconsDuotone.shieldCheck,
        color: AppColor.catCar,
        unlocked: budgetKept,
      ),
    ];

    return UserProgress(
      xp: xp,
      level: level,
      levelTitle: title,
      levelStartXp: xpForLevel(level),
      nextLevelXp: xpForLevel(level + 1),
      streak: streak,
      bestStreak: best,
      loggedToday: loggedToday,
      totalLogged: total,
      weekDays: week,
      badges: badges,
    );
  }
}
