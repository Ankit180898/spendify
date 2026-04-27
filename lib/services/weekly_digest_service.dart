import 'package:spendify/model/weekly_digest_model.dart';

class WeeklyDigestService {
  /// Computes the digest for the last complete Mon–Sun week.
  /// Returns null if there were no expense transactions that week.
  static WeeklyDigest? compute({
    required List<Map<String, dynamic>> allTransactions,
    required double monthlyBudget,
    required String sym,
  }) {
    final now = DateTime.now();

    // Last complete week boundaries (Mon 00:00 → Sun 23:59:59)
    final todayMon = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final weekStart = todayMon.subtract(const Duration(days: 7));
    final weekEnd = DateTime(
        todayMon.year, todayMon.month, todayMon.day - 1, 23, 59, 59);

    double amt(Map<String, dynamic> t) =>
        (t['amount'] as num?)?.toDouble() ?? 0.0;

    DateTime? parseDate(Map<String, dynamic> t) =>
        DateTime.tryParse(t['date'] ?? '');

    bool inWindow(Map<String, dynamic> t, DateTime from, DateTime to) {
      final d = parseDate(t);
      return d != null && !d.isBefore(from) && !d.isAfter(to) && t['type'] == 'expense';
    }

    final weekTxs = allTransactions.where((t) => inWindow(t, weekStart, weekEnd)).toList();
    if (weekTxs.isEmpty) return null;

    final totalSpent = weekTxs.fold(0.0, (s, t) => s + amt(t));

    // Previous week
    final prevStart = weekStart.subtract(const Duration(days: 7));
    final prevEnd = weekStart.subtract(const Duration(seconds: 1));
    final prevWeekSpent = allTransactions
        .where((t) => inWindow(t, prevStart, prevEnd))
        .fold(0.0, (s, t) => s + amt(t));

    // Top category
    final catMap = <String, double>{};
    for (final t in weekTxs) {
      final cat = (t['category'] as String?)?.isNotEmpty == true
          ? t['category'] as String
          : 'Others';
      catMap[cat] = (catMap[cat] ?? 0) + amt(t);
    }
    final topCatEntry = catMap.isNotEmpty
        ? catMap.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    // Biggest transaction
    final biggest = weekTxs.reduce((a, b) => amt(a) > amt(b) ? a : b);
    final biggestDesc = (biggest['description'] as String?)?.isNotEmpty == true
        ? biggest['description'] as String
        : (biggest['category'] as String?) ?? 'Transaction';

    // Weekend spend
    final weekendSpent = weekTxs.where((t) {
      final d = parseDate(t);
      return d != null && (d.weekday == 6 || d.weekday == 7);
    }).fold(0.0, (s, t) => s + amt(t));
    final weekendSpentPct = totalSpent > 0 ? (weekendSpent / totalSpent) : 0.0;

    final weekNum = weekNumber(weekStart);
    final weeklyBudget = monthlyBudget > 0 ? monthlyBudget / 4.33 : 0.0;

    final nudge = _nudge(
      totalSpent: totalSpent,
      prevWeekSpent: prevWeekSpent,
      biggestAmt: amt(biggest),
      txCount: weekTxs.length,
      weekendPct: weekendSpentPct,
    );

    return WeeklyDigest(
      weekNumber: weekNum,
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalSpent: totalSpent,
      prevWeekSpent: prevWeekSpent,
      topCategory: topCatEntry?.key ?? '',
      topCategoryAmount: topCatEntry?.value ?? 0,
      topCategoryPct: totalSpent > 0 && topCatEntry != null
          ? topCatEntry.value / totalSpent
          : 0,
      biggestTxDescription: biggestDesc,
      biggestTxAmount: amt(biggest),
      txCount: weekTxs.length,
      weeklyBudget: weeklyBudget,
      nudge: nudge,
      weekendSpentPct: weekendSpentPct,
    );
  }

  static int weekNumber(DateTime d) {
    final jan1 = DateTime(d.year, 1, 1);
    return ((d.difference(jan1).inDays + jan1.weekday) / 7).ceil();
  }

  static String _nudge({
    required double totalSpent,
    required double prevWeekSpent,
    required double biggestAmt,
    required int txCount,
    required double weekendPct,
  }) {
    if (totalSpent > 0 && biggestAmt / totalSpent > 0.35) {
      return '👀 One purchase was ${(biggestAmt / totalSpent * 100).round()}% of your whole week';
    }
    if (weekendPct > 0.6) {
      return '🎉 ${(weekendPct * 100).round()}% of your spending happened on weekends';
    }
    if (prevWeekSpent > 0) {
      final pct = ((totalSpent - prevWeekSpent) / prevWeekSpent * 100).round();
      if (pct >= 30) return '📈 Spending jumped $pct% vs last week';
      if (pct <= -20) return '📉 Down ${pct.abs()}% from last week — excellent!';
    }
    if (txCount <= 2) {
      return '📝 Only $txCount transactions logged — you may have missed some';
    }
    return '🔥 $txCount transactions tracked — keep it consistent for better insights';
  }
}
