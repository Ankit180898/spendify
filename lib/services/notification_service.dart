import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _budgetChannelId = 'budget_alerts';
  static const _savingsChannelId = 'savings_reminders';

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request POST_NOTIFICATIONS permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Budget alert (immediate, fires while app is open) ─────────────────────

  static Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _budgetChannelId,
          'Budget Alerts',
          channelDescription:
              'Alerts when you approach or exceed a spending limit',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ── Savings deadline reminders (scheduled, fires even when app is closed) ──

  static Future<void> scheduleSavingsReminder({
    required String goalId,
    required String goalName,
    required DateTime targetDate,
  }) async {
    final now = DateTime.now();

    // Set both reminders at 9:00 AM on the reminder day
    final sevenDaysBefore = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day - 7,
      9,
      0,
    );
    final oneDayBefore = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day - 1,
      9,
      0,
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _savingsChannelId,
        'Savings Reminders',
        channelDescription: 'Reminders for upcoming savings goal deadlines',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
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
  }

  static Future<void> cancelSavingsReminder(String goalId) async {
    await _plugin.cancel(goalId.hashCode.abs() % 2000000000);
    await _plugin.cancel((goalId.hashCode.abs() % 2000000000) + 1);
  }
}
