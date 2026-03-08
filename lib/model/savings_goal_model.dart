class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final String emoji;
  final DateTime? targetDate;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.emoji,
    this.targetDate,
    required this.createdAt,
  });

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      savedAmount: (map['saved_amount'] as num).toDouble(),
      emoji: (map['emoji'] as String?) ?? '🎯',
      targetDate: map['target_date'] != null
          ? DateTime.parse(map['target_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'emoji': emoji,
      if (targetDate != null)
        'target_date': targetDate!.toIso8601String().substring(0, 10),
    };
  }

  SavingsGoal copyWith({double? savedAmount}) {
    return SavingsGoal(
      id: id,
      userId: userId,
      name: name,
      targetAmount: targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      emoji: emoji,
      targetDate: targetDate,
      createdAt: createdAt,
    );
  }
}
