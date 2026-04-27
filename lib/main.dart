import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/theme_controller.dart';
import 'package:spendify/routes/app_pages.dart';
import 'package:spendify/services/connectivity_service.dart';
import 'package:spendify/services/notification_service.dart';
import 'package:spendify/services/widget_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:workmanager/workmanager.dart';

const _billCheckTask = 'bill_due_check';

@pragma('vm:entry-point')
void _workmanagerCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _billCheckTask) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_bills');
      if (raw == null) return true;

      final bills = List<Map<String, dynamic>>.from(jsonDecode(raw));
      final sym = prefs.getString('currency_symbol') ?? '₹';

      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
        ),
      );

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders', 'Bill Reminders',
          channelDescription: 'Reminders for upcoming recurring bills',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
      );

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int notifId = 500000;

      for (final bill in bills) {
        final dueDay = (bill['due_day'] as int).clamp(1, 28);
        final amount = (bill['amount'] as num).toDouble();
        final merchant = bill['merchant_name'] as String;

        var nextDue = DateTime(now.year, now.month, dueDay);
        if (!nextDue.isAfter(today.subtract(const Duration(days: 1)))) {
          nextDue = DateTime(now.year, now.month + 1, dueDay);
        }
        final daysUntil = nextDue.difference(today).inDays;

        if (daysUntil <= 3) {
          final msg = daysUntil == 0
              ? '$merchant is due today!'
              : '$merchant is due in $daysUntil day${daysUntil == 1 ? '' : 's'}.';
          await plugin.show(
            notifId++,
            'Bill due soon',
            '$sym${amount.toStringAsFixed(0)} — $msg',
            details,
          );
        }
      }
    } catch (e) {
      // background isolate — swallow errors silently
    }
    return true;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  GoogleFonts.config.allowRuntimeFetching = true;

  await dotenv.dotenv.load(fileName: '.env');
  await NotificationService.initialize();
  await WidgetService.init();
  Get.put(ConnectivityService(), permanent: true);
  final supaUri = dotenv.dotenv.env['SUPABASE_URL'];
  final supaAnon = dotenv.dotenv.env['SUPABASE_ANONKEY'];
  await Supabase.initialize(
    url: supaUri!,
    anonKey: supaAnon!,
  );

  await Workmanager().initialize(_workmanagerCallback);
  await Workmanager().registerPeriodicTask(
    _billCheckTask,
    _billCheckTask,
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(minutes: 1),
    constraints: Constraints(networkType: NetworkType.notRequired),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(const MyApp());
}

final supabaseC = Supabase.instance.client;
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialise the theme controller so it persists for the app lifetime.
    final themeController = Get.put(ThemeController());

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Spendify',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: themeController.themeMode,
        scaffoldMessengerKey: scaffoldMessengerKey,
        initialRoute: Routes.SPLASH,
        getPages: AppPages.routes,
        defaultTransition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }
}
