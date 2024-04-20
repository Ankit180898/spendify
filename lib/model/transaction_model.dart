class TransactionSummary {
  final String timePeriod;
  final double income;
  final double expense;

  TransactionSummary(this.timePeriod, this.income, this.expense);

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      json['timePeriod'] as String,
      json['income'] as double,
      json['expense'] as double,
    );
  }
}
