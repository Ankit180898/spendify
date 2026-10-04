import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/recurring_bill_model.dart';
import 'package:spendify/service/recurring_bill_detection_service.dart';
import 'package:spendify/services/notification_service.dart';

class RecurringBillsController extends GetxController {
  final bills = <RecurringBill>[].obs;
  final suggestions = <RecurringBillSuggestion>[].obs;
  final isLoading = false.obs;

  /// Lower-cased merchant names the user said "not a bill" to — kept so the
  /// same suggestion doesn't reappear on every refresh.
  final _dismissedNames = <String>{};

  @override
  void onInit() {
    super.onInit();
    fetchBills();
  }

  Future<void> fetchBills() async {
    isLoading.value = true;
    try {
      final uid = supabaseC.auth.currentUser?.id;
      if (uid == null) return;

      final data = await supabaseC
          .from('recurring_bills')
          .select()
          .eq('user_id', uid)
          .order('due_day');

      final all = (data as List)
          .map((e) => RecurringBill.fromJson(e as Map<String, dynamic>))
          .toList();
      _dismissedNames
        ..clear()
        ..addAll(all.where((b) => b.isDismissed).map((b) => b.merchantName.toLowerCase()));
      bills.value = all.where((b) => !b.isDismissed).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_bills',
        jsonEncode(bills
            .map((b) => {
                  'due_day': b.dueDay,
                  'amount': b.amount,
                  'merchant_name': b.merchantName,
                })
            .toList()),
      );

      _rescheduleBillNotifications();
      _detectSuggestions();
    } catch (e) {
      debugPrint('RecurringBillsController.fetchBills error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _detectSuggestions() {
    final hc = Get.find<HomeController>();
    final detected = RecurringBillDetectionService.detect(hc.allTransactions);
    final known = {
      ...bills.map((b) => b.merchantName.toLowerCase()),
      ..._dismissedNames,
    };
    suggestions.value = detected
        .where((s) => !known.contains(s.merchantName.toLowerCase()))
        .toList();
  }

  Future<bool> confirmSuggestion(RecurringBillSuggestion suggestion) async {
    final uid = supabaseC.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final data = await supabaseC
          .from('recurring_bills')
          .insert({
            'user_id': uid,
            'merchant_name': suggestion.merchantName,
            'amount': suggestion.avgAmount,
            'frequency': suggestion.frequency,
            'due_day': suggestion.suggestedDueDay,
            'is_active': true,
            'is_dismissed': false,
          })
          .select()
          .single();

      final bill = RecurringBill.fromJson(data);
      bills.add(bill);
      suggestions.removeWhere(
          (s) => s.merchantName.toLowerCase() == suggestion.merchantName.toLowerCase());

      await NotificationService.scheduleBillReminder(
        billId: bill.id,
        merchantName: bill.merchantName,
        amount: bill.amount,
        dueDay: bill.dueDay,
        currencySymbol: Get.find<HomeController>().currencySymbol.value,
      );
      return true;
    } catch (e) {
      debugPrint('RecurringBillsController.confirmSuggestion error: $e');
      return false;
    }
  }

  Future<void> dismissSuggestion(RecurringBillSuggestion suggestion) async {
    final uid = supabaseC.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await supabaseC.from('recurring_bills').insert({
        'user_id': uid,
        'merchant_name': suggestion.merchantName,
        'amount': suggestion.avgAmount,
        'frequency': suggestion.frequency,
        'due_day': suggestion.suggestedDueDay,
        'is_active': false,
        'is_dismissed': true,
      });
      _dismissedNames.add(suggestion.merchantName.toLowerCase());
      suggestions.removeWhere((s) =>
          s.merchantName.toLowerCase() == suggestion.merchantName.toLowerCase());
    } catch (e) {
      debugPrint('RecurringBillsController.dismissSuggestion error: $e');
    }
  }

  Future<bool> addBillManually({
    required String merchantName,
    required double amount,
    required String frequency,
    required int dueDay,
  }) async {
    final uid = supabaseC.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final data = await supabaseC
          .from('recurring_bills')
          .insert({
            'user_id': uid,
            'merchant_name': merchantName,
            'amount': amount,
            'frequency': frequency,
            'due_day': dueDay,
            'is_active': true,
            'is_dismissed': false,
          })
          .select()
          .single();

      final bill = RecurringBill.fromJson(data);
      bills.add(bill);

      await NotificationService.scheduleBillReminder(
        billId: bill.id,
        merchantName: bill.merchantName,
        amount: bill.amount,
        dueDay: bill.dueDay,
        currencySymbol: Get.find<HomeController>().currencySymbol.value,
      );
      return true;
    } catch (e) {
      debugPrint('RecurringBillsController.addBillManually error: $e');
      return false;
    }
  }

  /// Removes locally first so a swiped row disappears immediately; restores
  /// it if the delete fails.
  Future<bool> deleteBill(String billId) async {
    final idx = bills.indexWhere((b) => b.id == billId);
    if (idx == -1) return false;
    final removed = bills.removeAt(idx);
    try {
      await supabaseC.from('recurring_bills').delete().eq('id', billId);
      await NotificationService.cancelBillReminder(billId);
      return true;
    } catch (e) {
      debugPrint('RecurringBillsController.deleteBill error: $e');
      bills.insert(idx.clamp(0, bills.length), removed);
      return false;
    }
  }

  /// Marks the cycle due on [due] as paid, or un-marks it (falling back to
  /// the previous cycle) when [paid] is false.
  Future<bool> setPaid(RecurringBill bill, DateTime due, {bool paid = true}) async {
    final idx = bills.indexWhere((b) => b.id == bill.id);
    if (idx == -1) return false;
    final settled = paid
        ? due
        : bill.dueDateIn(due.year, due.month - bill.monthsPerCycle);
    try {
      await supabaseC
          .from('recurring_bills')
          .update({'last_paid_at': settled.toIso8601String()})
          .eq('id', bill.id);
      bills[idx] = bill.withLastPaidAt(settled);
      return true;
    } catch (e) {
      debugPrint('RecurringBillsController.setPaid error: $e');
      return false;
    }
  }

  /// Called after an expense is saved (manual entry or UPI capture). Marks
  /// any unpaid bill whose name matches the transaction title as paid.
  /// Returns the bills that were marked.
  Future<List<RecurringBill>> autoMarkPaid(String merchantName) async {
    final marked = <RecurringBill>[];
    final uid = supabaseC.auth.currentUser?.id;
    final normalized = merchantName.toLowerCase().trim();
    if (uid == null || normalized.length < 3) return marked;

    final matching = bills.where((b) {
      final bName = b.merchantName.toLowerCase().trim();
      if (bName.length < 3) return false;
      return bName.contains(normalized) || normalized.contains(bName);
    }).toList();

    if (matching.isEmpty) return marked;

    for (final bill in matching) {
      final due = bill.payableDueDate;
      if (due == null) continue;
      try {
        await supabaseC
            .from('recurring_bills')
            .update({'last_paid_at': due.toIso8601String()})
            .eq('id', bill.id);

        final idx = bills.indexWhere((b) => b.id == bill.id);
        if (idx != -1) {
          bills[idx] = bill.withLastPaidAt(due);
          marked.add(bills[idx]);
        }
      } catch (e) {
        debugPrint('RecurringBillsController.autoMarkPaid error: $e');
      }
    }
    return marked;
  }

  void _rescheduleBillNotifications() {
    final sym = Get.find<HomeController>().currencySymbol.value;
    for (final bill in bills) {
      if (!bill.isActive) continue;
      NotificationService.scheduleBillReminder(
        billId: bill.id,
        merchantName: bill.merchantName,
        amount: bill.amount,
        dueDay: bill.dueDay,
        currencySymbol: sym,
      );
    }
  }
}
