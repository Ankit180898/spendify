class WeeklyDigest {
  final int weekNumber;
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalSpent;
  final double prevWeekSpent;
  final String topCategory;
  final double topCategoryAmount;
  final double topCategoryPct;
  final String biggestTxDescription;
  final double biggestTxAmount;
  final int txCount;
  final double weeklyBudget;
  final String nudge;
  final double weekendSpentPct;

  const WeeklyDigest({
    required this.weekNumber,
    required this.weekStart,
    required this.weekEnd,
    required this.totalSpent,
    required this.prevWeekSpent,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.topCategoryPct,
    required this.biggestTxDescription,
    required this.biggestTxAmount,
    required this.txCount,
    required this.weeklyBudget,
    required this.nudge,
    required this.weekendSpentPct,
  });
}
