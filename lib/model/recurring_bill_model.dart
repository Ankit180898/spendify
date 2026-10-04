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

  /// Unlike [copyWith], can also clear the payment (pass null).
  RecurringBill withLastPaidAt(DateTime? paidAt) => RecurringBill(
        id: id,
        userId: userId,
        merchantName: merchantName,
        amount: amount,
        frequency: frequency,
        dueDay: dueDay,
        lastPaidAt: paidAt,
        isActive: isActive,
        isDismissed: isDismissed,
        createdAt: createdAt,
      );

  static int _clampDay(int day, int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day.clamp(1, lastDay);
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime get _today => _dayOf(DateTime.now());

  int get monthsPerCycle => frequency == 'yearly'
      ? 12
      : frequency == 'quarterly'
          ? 3
          : 1;

  /// Monthly bills are due every month; quarterly/yearly bills are due in
  /// months that line up with the month the bill was added.
  bool isDueInMonth(int year, int month) {
    if (monthsPerCycle == 1) return true;
    final diff = (year * 12 + month) - (createdAt.year * 12 + createdAt.month);
    return diff % monthsPerCycle == 0;
  }

  /// Due date inside a given month — day clamped so a "31st" bill still
  /// lands on Feb 28/29 instead of disappearing.
  DateTime dueDateIn(int year, int month) =>
      DateTime(year, month, _clampDay(dueDay, year, month));

  /// Most recent due date on or before today, ignoring dates before the bill
  /// was added (those cycles were never tracked).
  DateTime? get lastDueDate {
    final t = _today;
    final added = _dayOf(createdAt);
    for (var i = 0; i <= 12; i++) {
      final m = DateTime(t.year, t.month - i);
      if (!isDueInMonth(m.year, m.month)) continue;
      final d = dueDateIn(m.year, m.month);
      if (d.isAfter(t)) continue;
      return d.isBefore(added) ? null : d;
    }
    return null;
  }

  /// First due date strictly after today.
  DateTime get nextDueDate {
    final t = _today;
    for (var i = 0; i <= 13; i++) {
      final m = DateTime(t.year, t.month + i);
      if (!isDueInMonth(m.year, m.month)) continue;
      final d = dueDateIn(m.year, m.month);
      if (d.isAfter(t)) return d;
    }
    return dueDateIn(t.year, t.month + 1);
  }

  /// `last_paid_at` stores the due date of the latest cycle that was settled
  /// (see [RecurringBillsController.setPaid]), so a cycle is paid when that
  /// date is on or after it — regardless of whether it was paid early or late.
  bool isPaidFor(DateTime due) =>
      lastPaidAt != null && !_dayOf(lastPaidAt!.toLocal()).isBefore(due);

  /// The cycle an incoming payment most likely settles: an overdue or
  /// due-today bill, or one due within the next 10 days. Null otherwise.
  DateTime? get payableDueDate {
    if (isOverdue || _isDueToday) return lastDueDate;
    final next = nextDueDate;
    if (isPaidFor(next)) return null;
    return next.difference(_today).inDays <= 10 ? next : null;
  }

  bool get isOverdue {
    final d = lastDueDate;
    return d != null && d != _today && !isPaidFor(d);
  }

  bool get _isDueToday {
    final d = lastDueDate;
    return d != null && d == _today && !isPaidFor(d);
  }

  /// The due date the user should care about right now.
  DateTime get currentDueDate =>
      (isOverdue || _isDueToday) ? lastDueDate! : nextDueDate;

  /// Days until [currentDueDate]; negative when overdue.
  int get daysUntilDue => currentDueDate.difference(_today).inDays;

  bool get isPaidThisCycle {
    if (isOverdue || _isDueToday) return false;
    if (isPaidFor(nextDueDate)) return true;
    // Just paid the last one and the next is still a while away
    final last = lastDueDate;
    return last != null && isPaidFor(last) && daysUntilDue > 7;
  }

  String get statusLabel {
    if (isPaidThisCycle) return 'Paid';
    final days = daysUntilDue;
    if (days < 0) return days == -1 ? 'Overdue · 1 day' : 'Overdue · ${-days} days';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  bool get isUrgent => !isPaidThisCycle && daysUntilDue <= 2;

  /// Monthly-equivalent cost, for totals across mixed frequencies.
  double get monthlyCost => amount / monthsPerCycle;
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
