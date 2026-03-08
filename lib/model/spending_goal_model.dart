class SpendingGoal {
  final String id;
  final String userId;
  final String category; // 'All' or a specific category name
  final double limitAmount;
  final String period; // 'monthly' or 'weekly'

  SpendingGoal({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.period,
  });

  factory SpendingGoal.fromMap(Map<String, dynamic> map) {
    return SpendingGoal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      category: map['category'] as String,
      limitAmount: (map['limit_amount'] as num).toDouble(),
      period: map['period'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category': category,
      'limit_amount': limitAmount,
      'period': period,
    };
  }
}
