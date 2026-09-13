import 'package:spendify/model/recurring_bill_model.dart';

class RecurringBillDetectionService {
  RecurringBillDetectionService._();

  static const _monthlyMin = 25;
  static const _monthlyMax = 35;
  static const _quarterlyMin = 80;
  static const _quarterlyMax = 100;
  static const _yearlyMin = 350;
  static const _yearlyMax = 380;

  static List<RecurringBillSuggestion> detect(
    List<Map<String, dynamic>> allTransactions,
  ) {
    final expenses = allTransactions.where((t) => t['type'] == 'expense').toList();

    // Group by normalized merchant name
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final t in expenses) {
      final merchant = (t['description'] as String? ?? '').trim().toLowerCase();
      if (merchant.isEmpty || merchant.length < 2) continue;
      groups.putIfAbsent(merchant, () => []).add(t);
    }

    final suggestions = <RecurringBillSuggestion>[];

    for (final entry in groups.entries) {
      if (entry.value.length < 2) continue;

      final sorted = entry.value.toList()
        ..sort((a, b) {
          final da = a['parsedDate'] as DateTime?;
          final db = b['parsedDate'] as DateTime?;
          if (da == null || db == null) return 0;
          return da.compareTo(db);
        });

      final dates = sorted
          .map((t) => t['parsedDate'] as DateTime?)
          .whereType<DateTime>()
          .toList();
      if (dates.length < 2) continue;

      final intervals = <int>[];
      for (int i = 1; i < dates.length; i++) {
        intervals.add(dates[i].difference(dates[i - 1]).inDays);
      }
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

      String? frequency;
      if (avgInterval >= _monthlyMin && avgInterval <= _monthlyMax) {
        frequency = 'monthly';
      } else if (avgInterval >= _quarterlyMin && avgInterval <= _quarterlyMax) {
        frequency = 'quarterly';
      } else if (avgInterval >= _yearlyMin && avgInterval <= _yearlyMax) {
        frequency = 'yearly';
      }
      if (frequency == null) continue;

      // Require amount consistency within ±20%
      final amounts = sorted
          .map((t) => (t['amount'] as num).toDouble())
          .toList();
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final consistent = amounts
          .every((a) => avgAmount == 0 || (a - avgAmount).abs() / avgAmount <= 0.20);
      if (!consistent && sorted.length < 3) continue;

      // Most common due day
      final dayFreq = <int, int>{};
      for (final d in dates) {
        dayFreq[d.day] = (dayFreq[d.day] ?? 0) + 1;
      }
      final suggestedDay =
          dayFreq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      final category = sorted.last['category'] as String? ?? 'Others';

      suggestions.add(RecurringBillSuggestion(
        merchantName: _titleCase(entry.key),
        avgAmount: double.parse(avgAmount.toStringAsFixed(2)),
        frequency: frequency,
        suggestedDueDay: suggestedDay.clamp(1, 28),
        category: category,
        occurrences: sorted.length,
      ));
    }

    // Sort: more occurrences first, then by merchant name
    suggestions.sort((a, b) {
      final cmp = b.occurrences.compareTo(a.occurrences);
      return cmp != 0 ? cmp : a.merchantName.compareTo(b.merchantName);
    });

    return suggestions;
  }

  static String _titleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
