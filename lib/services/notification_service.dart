import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _budgetChannelId    = 'budget_alerts';
  static const _savingsChannelId   = 'savings_reminders';
  static const _logChannelId       = 'log_reminders';
  static const _weeklyChannelId    = 'weekly_digest';
  static const _monthlyChannelId   = 'monthly_recap';
  static const _dailyChannelId     = 'daily_safe';
  static const _milestoneChannelId = 'milestones';
  static const _spikeChannelId     = 'spend_spike';
  static const _splitsChannelId    = 'group_splits';
  static const _billChannelId      = 'bill_reminders';

  static const _logReminderId   = 999999;
  static const _weeklyDigestId  = 1000001;
  static const _monthlyRecapId  = 1000002;
  static const _dailySafeId     = 1000003;

  static const _icon = '@drawable/ic_launcher_foreground';

  // Monotonic counter — avoids ID collisions between rapid immediate notifications
  static int _nextImmediateId = 1;
  static int _immediateId() {
    final id = _nextImmediateId;
    _nextImmediateId = (_nextImmediateId % 9000) + 1;
    return id;
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings(_icon),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.initialize error: $e');
    }
  }

  // ── Budget alert (immediate) ───────────────────────────────────────────────

  static Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        _immediateId(),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _budgetChannelId, 'Budget Alerts',
            channelDescription: 'Alerts when you approach or exceed a spending limit',
            importance: Importance.high,
            priority: Priority.high,
            icon: _icon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('showBudgetAlert error: $e');
    }
  }

  // ── Savings deadline reminders (scheduled) ────────────────────────────────

  static Future<void> scheduleSavingsReminder({
    required String goalId,
    required String goalName,
    required DateTime targetDate,
  }) async {
    if (!_initialized) return;
    try {
      final now = DateTime.now();
      final sevenDaysBefore = DateTime(
        targetDate.year, targetDate.month, targetDate.day - 7, 9, 0,
      );
      final oneDayBefore = DateTime(
        targetDate.year, targetDate.month, targetDate.day - 1, 9, 0,
      );

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _savingsChannelId, 'Savings Reminders',
          channelDescription: 'Reminders for upcoming savings goal deadlines',
          importance: Importance.high,
          priority: Priority.high,
          icon: _icon,
        ),
        iOS: DarwinNotificationDetails(),
      );

      if (sevenDaysBefore.isAfter(now)) {
        await _plugin.zonedSchedule(
          goalId.hashCode.abs() % 2000000000,
          'Savings Reminder',
          '$goalName deadline is in 7 days!',
          tz.TZDateTime.from(sevenDaysBefore, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      if (oneDayBefore.isAfter(now)) {
        await _plugin.zonedSchedule(
          (goalId.hashCode.abs() % 2000000000) + 1,
          'Last Reminder',
          '$goalName deadline is tomorrow!',
          tz.TZDateTime.from(oneDayBefore, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('scheduleSavingsReminder error: $e');
    }
  }

  static Future<void> cancelSavingsReminder(String goalId) async {
    try {
      await _plugin.cancel(goalId.hashCode.abs() % 2000000000);
      await _plugin.cancel((goalId.hashCode.abs() % 2000000000) + 1);
    } catch (e) {
      debugPrint('cancelSavingsReminder error: $e');
    }
  }

  // ── Log reminder ──────────────────────────────────────────────────────────

  static Future<void> rescheduleLogReminder({int afterDays = 3}) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_logReminderId);

      final fireAt = DateTime.now().add(Duration(days: afterDays));
      final scheduled = DateTime(fireAt.year, fireAt.month, fireAt.day, 10, 0);

      await _plugin.zonedSchedule(
        _logReminderId,
        'Quick check-in 📝',
        'You haven\'t logged in $afterDays days — tap to add a transaction.',
        tz.TZDateTime.from(scheduled, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _logChannelId, 'Log Reminders',
            channelDescription: 'Reminds you to log transactions regularly',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: _icon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('rescheduleLogReminder error: $e');
    }
  }

  // ── Weekly digest (scheduled every Monday 9 AM) ───────────────────────────

  static Future<void> scheduleWeeklyDigest({
    required double thisWeekSpent,
    required double lastWeekSpent,
    required String topCategory,
    required String sym,
  }) async {
    if (!_initialized) return;
    try {
      final now = DateTime.now();
      final daysUntilMonday = (8 - now.weekday) % 7;
      final nextMondayDate = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
      final nextMonday = DateTime(nextMondayDate.year, nextMondayDate.month, nextMondayDate.day, 9, 0);

      final diff = thisWeekSpent - lastWeekSpent;
      final sign = diff >= 0 ? '+' : '-';
      final body = topCategory.isNotEmpty
          ? '$topCategory was your top spend. $sign$sym${diff.abs().toStringAsFixed(0)} vs last week.'
          : '$sign$sym${diff.abs().toStringAsFixed(0)} vs last week.';

      await _plugin.cancel(_weeklyDigestId);
      await _plugin.zonedSchedule(
        _weeklyDigestId,
        'Weekly digest: $sym${thisWeekSpent.toStringAsFixed(0)} spent',
        body,
        tz.TZDateTime.from(nextMonday, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _weeklyChannelId, 'Weekly Digest',
            channelDescription: 'Weekly spending summary every Monday morning',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: _icon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('scheduleWeeklyDigest error: $e');
    }
  }

  // ── Monthly recap (scheduled for 1st of next month 9 AM) ─────────────────

  static Future<void> scheduleMonthlyRecap({
    required double totalSpent,
    required double totalIncome,
    required String topCategory,
    required String sym,
    required int currentMonth,
    required int currentYear,
  }) async {
    if (!_initialized) return;
    try {
      final firstOfNextMonth = DateTime(currentYear, currentMonth + 1, 1, 9, 0);
      final saved = totalIncome - totalSpent;
      final savedText = saved >= 0
          ? 'Saved $sym${saved.toStringAsFixed(0)}.'
          : 'Overspent by $sym${saved.abs().toStringAsFixed(0)}.';
      final body = '$sym${totalSpent.toStringAsFixed(0)} spent. $savedText'
          '${topCategory.isNotEmpty ? ' Top: $topCategory.' : ''}';

      await _plugin.cancel(_monthlyRecapId);
      await _plugin.zonedSchedule(
        _monthlyRecapId,
        'Monthly recap — ${_monthName(currentMonth)}',
        body,
        tz.TZDateTime.from(firstOfNextMonth, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _monthlyChannelId, 'Monthly Recap',
            channelDescription: 'Monthly spending recap on the 1st of each month',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: _icon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('scheduleMonthlyRecap error: $e');
    }
  }

  // ── Daily safe-to-spend (scheduled for tomorrow 9 AM) ────────────────────

  static Future<void> scheduleDailySafeToSpend({
    required double safeAmount,
    required String sym,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_dailySafeId);
      if (safeAmount <= 0) return;

      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 0);

      await _plugin.zonedSchedule(
        _dailySafeId,
        'Safe to spend today: $sym${safeAmount.toStringAsFixed(0)}',
        'Stay on track with your monthly budget.',
        tz.TZDateTime.from(tomorrow, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyChannelId, 'Daily Budget',
            channelDescription: 'Daily safe-to-spend amount based on your budget',
            importance: Importance.low,
            priority: Priority.low,
            icon: _icon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('scheduleDailySafeToSpend error: $e');
    }
  }

  // ── Celebratory milestone (immediate) ─────────────────────────────────────

  static Future<void> showMilestone(String title, String body) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        _immediateId(),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _milestoneChannelId, 'Milestones',
            channelDescription: 'Celebratory notifications for hitting goals',
            importance: Importance.high,
            priority: Priority.high,
            icon: _icon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('showMilestone error: $e');
    }
  }

  // ── Spend spike (immediate) ───────────────────────────────────────────────

  static Future<void> showSpendSpike({
    required String category,
    required double thisWeek,
    required double avgWeek,
    required String sym,
  }) async {
    if (!_initialized) return;
    try {
      final pct = ((thisWeek - avgWeek) / avgWeek * 100).toInt();
      await _plugin.show(
        _immediateId(),
        'Spending spike: $category',
        '$sym${thisWeek.toStringAsFixed(0)} this week — $pct% above your average.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _spikeChannelId, 'Spend Spikes',
            channelDescription: 'Alerts when a category is unusually high this week',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: _icon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('showSpendSpike error: $e');
    }
  }

  // ── Group splits / shared expenses (immediate) ───────────────────────────────

  static Future<void> showSplitAlert({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        _immediateId(),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _splitsChannelId, 'Group Splits',
            channelDescription: 'Notifications for group joins, leaves and shared expenses',
            importance: Importance.high,
            priority: Priority.high,
            icon: _icon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('showSplitAlert error: $e');
    }
  }

  // ── Bill reminders (recurring monthly) ───────────────────────────────────

  static Future<void> scheduleBillReminder({
    required String billId,
    required String merchantName,
    required double amount,
    required int dueDay,
    required String currencySymbol,
  }) async {
    if (!_initialized) return;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final clampedDay = dueDay.clamp(1, 28);

      // Calculate next due date
      var nextDue = DateTime(now.year, now.month, clampedDay);
      if (!nextDue.isAfter(today.subtract(const Duration(days: 1)))) {
        nextDue = DateTime(now.year, now.month + 1, clampedDay);
      }
      final daysUntilDue = nextDue.difference(today).inDays;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _billChannelId, 'Bill Reminders',
          channelDescription: 'Reminders for upcoming recurring bills',
          importance: Importance.high,
          priority: Priority.high,
          icon: _icon,
        ),
        iOS: DarwinNotificationDetails(),
      );

      final baseId = (billId.hashCode.abs() % 100000000) + 200000000;

      // If due within 3 days, fire an immediate notification right now
      if (daysUntilDue <= 3) {
        final msg = daysUntilDue <= 0
            ? '$merchantName is due today!'
            : '$merchantName is due in $daysUntilDue day${daysUntilDue == 1 ? '' : 's'}.';
        await _plugin.show(
          baseId,
          'Bill due soon',
          '$currencySymbol${amount.toStringAsFixed(0)} — $msg',
          details,
        );
      }

      // Schedule monthly recurring reminder 2 days before due date for future months
      final reminderDay = (clampedDay - 2).clamp(1, 28);
      var fireDate = DateTime(now.year, now.month, reminderDay, 9, 0);
      // If this month's reminder is already covered by the immediate above, start from next month
      if (daysUntilDue <= 3 || !fireDate.isAfter(now)) {
        fireDate = DateTime(now.year, now.month + 1, reminderDay, 9, 0);
      }

      if (clampedDay >= 3) {
        await _plugin.zonedSchedule(
          baseId + 1,
          'Bill due soon',
          '$merchantName — $currencySymbol${amount.toStringAsFixed(0)} is due in 2 days.',
          tz.TZDateTime.from(fireDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );
      } else {
        await _plugin.zonedSchedule(
          baseId + 1,
          'Bill due soon',
          '$merchantName — $currencySymbol${amount.toStringAsFixed(0)} is due soon.',
          tz.TZDateTime.from(fireDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('scheduleBillReminder error: $e');
    }
  }

  static Future<void> cancelBillReminder(String billId) async {
    try {
      final baseId = (billId.hashCode.abs() % 100000000) + 200000000;
      await _plugin.cancel(baseId);
      await _plugin.cancel(baseId + 1);
    } catch (e) {
      debugPrint('cancelBillReminder error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[(month - 1).clamp(0, 11)];
  }
}
