import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/recurring_bills_controller/recurring_bills_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/service/upi_notification_service.dart';
import 'package:spendify/widgets/upi_confirm_sheet.dart';

class UpiCaptureController extends GetxController with WidgetsBindingObserver {
  static const _permPromptedKey = 'upi_perm_prompted';

  final pendingCaptures = <UpiCapture>[].obs;
  final isPermissionGranted = false.obs;

  StreamSubscription<ServiceNotificationEvent>? _sub;
  bool _sheetOpen = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initListener();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permission after returning from Settings
      _initListener();
      // Show pending captures that arrived while app was in background
      if (pendingCaptures.isNotEmpty && !_sheetOpen) {
        Future.delayed(const Duration(milliseconds: 400), _showSheet);
      }
    }
  }

  Future<void> _initListener() async {
    final granted = await NotificationListenerService.isPermissionGranted();
    isPermissionGranted.value = granted;
    if (!granted || _sub != null) return;

    _sub = NotificationListenerService.notificationsStream.listen(_onEvent);
  }

  void _onEvent(ServiceNotificationEvent event) {
    final capture = UpiNotificationService.parse(
      packageName: event.packageName ?? '',
      title: event.title,
      content: event.content,
    );
    if (capture == null) return;

    pendingCaptures.add(capture);

    if (!_sheetOpen) _showSheet();
  }

  void _showSheet() {
    if (pendingCaptures.isEmpty) return;
    final route = Get.currentRoute;
    if (route == '/onboarding' || route == '/login' || route == '/getStarted' || route == '/splash') return;
    _sheetOpen = true;
    Get.bottomSheet(
      const UpiConfirmSheet(),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
    ).then((_) => _sheetOpen = false);
  }

  Future<void> saveCapture(UpiCapture capture, String selectedCategory) async {
    try {
      final uid = supabaseC.auth.currentUser?.id;
      if (uid == null) return;

      await supabaseC.from('transactions').insert({
        'user_id': uid,
        'amount': capture.amount,
        'description': capture.merchant,
        'type': capture.type,
        'category': selectedCategory,
        'date': capture.capturedAt.toIso8601String(),
      });

      final homeC = Get.find<HomeController>();
      final newBalance = capture.type == 'income'
          ? homeC.totalBalance.value + capture.amount
          : homeC.totalBalance.value - capture.amount;

      await supabaseC.from('users').update({'balance': newBalance}).eq('id', uid);
      homeC.totalBalance.value = newBalance;

      await homeC.fetchTotalBalanceData();
      await homeC.getTransactions();

      pendingCaptures.remove(capture);

      if (Get.isRegistered<RecurringBillsController>()) {
        Get.find<RecurringBillsController>().autoMarkPaid(capture.merchant);
      }
    } catch (e) {
      debugPrint('UpiCaptureController.saveCapture error: $e');
    }
  }

  void dismissCapture(UpiCapture capture) {
    pendingCaptures.remove(capture);
  }

  void dismissAll() {
    pendingCaptures.clear();
  }

  // Returns true if we should show the permission prompt screen.
  // Only shows once; after that the user can enable it from Profile settings.
  Future<bool> shouldPromptPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted = prefs.getBool(_permPromptedKey) ?? false;
    if (alreadyPrompted) return false;
    final granted = await NotificationListenerService.isPermissionGranted();
    return !granted;
  }

  Future<void> markPermissionPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permPromptedKey, true);
  }

  Future<void> requestPermission() async {
    await markPermissionPrompted();
    await NotificationListenerService.requestPermission();
  }
}
