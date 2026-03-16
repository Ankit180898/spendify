class SplitModel {
  final String id;
  final String groupId;
  final String title;
  final double totalAmount;
  final String paidBy;
  final String category;
  final DateTime date;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  List<SplitShare> shares;

  SplitModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.totalAmount,
    required this.paidBy,
    required this.category,
    required this.date,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.shares = const [],
  });

  factory SplitModel.fromMap(Map<String, dynamic> m) => SplitModel(
        id: m['id'] as String,
        groupId: m['group_id'] as String,
        title: m['title'] as String,
        totalAmount: (m['total_amount'] as num).toDouble(),
        paidBy: m['paid_by'] as String,
        category: (m['category'] as String?) ?? 'Others',
        date: DateTime.parse(m['date'] as String),
        notes: m['notes'] as String?,
        createdBy: m['created_by'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class SplitShare {
  final String id;
  final String splitId;
  final String userId;
  final double amountOwed;
  final bool isSettled;
  final DateTime? settledAt;

  const SplitShare({
    required this.id,
    required this.splitId,
    required this.userId,
    required this.amountOwed,
    required this.isSettled,
    this.settledAt,
  });

  factory SplitShare.fromMap(Map<String, dynamic> m) => SplitShare(
        id: m['id'] as String,
        splitId: m['split_id'] as String,
        userId: m['user_id'] as String,
        amountOwed: (m['amount_owed'] as num).toDouble(),
        isSettled: (m['is_settled'] as bool?) ?? false,
        settledAt: m['settled_at'] != null
            ? DateTime.parse(m['settled_at'] as String)
            : null,
      );

  SplitShare copyWith({bool? isSettled, DateTime? settledAt}) => SplitShare(
        id: id,
        splitId: splitId,
        userId: userId,
        amountOwed: amountOwed,
        isSettled: isSettled ?? this.isSettled,
        settledAt: settledAt ?? this.settledAt,
      );
}
