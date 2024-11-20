class SavingsGoal {
  final String id;
  final String userId;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
  });

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      userId: map['user_id'],
      goalName: map['goal_name'],
      targetAmount: map['target_amount'],
      currentAmount: map['current_amount'],
      targetDate: DateTime.parse(map['target_date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'goal_name': goalName,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String(),
    };
  }
}
