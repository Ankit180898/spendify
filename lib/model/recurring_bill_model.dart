class RecurringBill {
  final String id;
  final String userId;
  final String merchantName;
  final double amount;
  final String frequency; // 'monthly' | 'quarterly' | 'yearly'
  final int dueDay;
  final DateTime? lastPaidAt;
  final bool isActive;
  final bool isDismissed;
  final DateTime createdAt;

  const RecurringBill({
    required this.id,
    required this.userId,
    required this.merchantName,
    required this.amount,
    required this.frequency,
    required this.dueDay,
    this.lastPaidAt,
    required this.isActive,
    required this.isDismissed,
    required this.createdAt,
  });

  factory RecurringBill.fromJson(Map<String, dynamic> json) => RecurringBill(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        merchantName: json['merchant_name'] as String,
        amount: (json['amount'] as num).toDouble(),
        frequency: json['frequency'] as String,
        dueDay: json['due_day'] as int,
        lastPaidAt: json['last_paid_at'] != null
            ? DateTime.parse(json['last_paid_at'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
        isDismissed: json['is_dismissed'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  RecurringBill copyWith({DateTime? lastPaidAt}) => RecurringBill(
        id: id,
        userId: userId,
        merchantName: merchantName,
        amount: amount,
        frequency: frequency,
        dueDay: dueDay,
        lastPaidAt: lastPaidAt ?? this.lastPaidAt,
        isActive: isActive,
        isDismissed: isDismissed,
        createdAt: createdAt,
      );

  DateTime get nextDueDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var candidate = DateTime(now.year, now.month, dueDay.clamp(1, 28));
    if (!candidate.isAfter(today.subtract(const Duration(days: 1)))) {
      candidate = DateTime(now.year, now.month + 1, dueDay.clamp(1, 28));
    }
    return candidate;
  }

  int get daysUntilDue {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return nextDueDate.difference(today).inDays;
  }

  bool get isPaidThisCycle {
    if (lastPaidAt == null) return false;
    final now = DateTime.now();
    switch (frequency) {
      case 'monthly':
        return lastPaidAt!.year == now.year && lastPaidAt!.month == now.month;
      case 'quarterly':
        return now.difference(lastPaidAt!).inDays <= 90;
      case 'yearly':
        return now.difference(lastPaidAt!).inDays <= 365;
      default:
        return false;
    }
  }

  String get statusLabel {
    if (isPaidThisCycle) return 'Paid';
    final days = daysUntilDue;
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  bool get isUrgent => !isPaidThisCycle && daysUntilDue <= 2;
  bool get isOverdue => !isPaidThisCycle && daysUntilDue < 0;
}

class RecurringBillSuggestion {
  final String merchantName;
  final double avgAmount;
  final String frequency;
  final int suggestedDueDay;
  final String category;
  final int occurrences;

  const RecurringBillSuggestion({
    required this.merchantName,
    required this.avgAmount,
    required this.frequency,
    required this.suggestedDueDay,
    required this.category,
    required this.occurrences,
  });
}
