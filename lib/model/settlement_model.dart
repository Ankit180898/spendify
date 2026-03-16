class SettlementModel {
  final String id;
  final String groupId;
  final String fromUser;
  final String toUser;
  final double amount;
  final String? note;
  final DateTime createdAt;

  const SettlementModel({
    required this.id,
    required this.groupId,
    required this.fromUser,
    required this.toUser,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  factory SettlementModel.fromMap(Map<String, dynamic> m) => SettlementModel(
        id: m['id'] as String,
        groupId: m['group_id'] as String,
        fromUser: m['from_user'] as String,
        toUser: m['to_user'] as String,
        amount: (m['amount'] as num).toDouble(),
        note: m['note'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

/// Represents a simplified debt: [fromUser] owes [toUser] [amount]
class DebtEntry {
  final String fromUserId;
  final String fromName;
  final String toUserId;
  final String toName;
  final double amount;

  const DebtEntry({
    required this.fromUserId,
    required this.fromName,
    required this.toUserId,
    required this.toName,
    required this.amount,
  });
}
