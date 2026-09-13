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
          .eq('is_dismissed', false)
          .order('due_day');

      bills.value =
          (data as List).map((e) => RecurringBill.fromJson(e as Map<String, dynamic>)).toList();

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
    final confirmedNames = bills.map((b) => b.merchantName.toLowerCase()).toSet();
    suggestions.value = detected
        .where((s) => !confirmedNames.contains(s.merchantName.toLowerCase()))
        .toList();
  }

  Future<void> confirmSuggestion(RecurringBillSuggestion suggestion) async {
    final uid = supabaseC.auth.currentUser?.id;
    if (uid == null) return;
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
    } catch (e) {
      debugPrint('RecurringBillsController.confirmSuggestion error: $e');
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
      suggestions.removeWhere((s) => s.merchantName == suggestion.merchantName);
    } catch (e) {
      debugPrint('RecurringBillsController.dismissSuggestion error: $e');
    }
  }

  Future<void> addBillManually({
    required String merchantName,
    required double amount,
    required String frequency,
    required int dueDay,
  }) async {
    final uid = supabaseC.auth.currentUser?.id;
    if (uid == null) return;
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
    } catch (e) {
      debugPrint('RecurringBillsController.addBillManually error: $e');
    }
  }

  Future<void> deleteBill(String billId) async {
    try {
      await supabaseC.from('recurring_bills').delete().eq('id', billId);
      await NotificationService.cancelBillReminder(billId);
      bills.removeWhere((b) => b.id == billId);
    } catch (e) {
      debugPrint('RecurringBillsController.deleteBill error: $e');
    }
  }

  // Called from UpiCaptureController after a transaction is saved
  Future<void> autoMarkPaid(String merchantName) async {
    final uid = supabaseC.auth.currentUser?.id;
    if (uid == null) return;
    final normalized = merchantName.toLowerCase();

    final matching = bills.where((b) {
      final bName = b.merchantName.toLowerCase();
      return bName.contains(normalized) || normalized.contains(bName);
    }).toList();

    if (matching.isEmpty) return;

    final now = DateTime.now();
    for (final bill in matching) {
      if (bill.isPaidThisCycle) continue;
      try {
        await supabaseC
            .from('recurring_bills')
            .update({'last_paid_at': now.toIso8601String()})
            .eq('id', bill.id);

        final idx = bills.indexWhere((b) => b.id == bill.id);
        if (idx != -1) {
          bills.removeAt(idx);
          bills.insert(idx, bill.copyWith(lastPaidAt: now));
        }
      } catch (e) {
        debugPrint('RecurringBillsController.autoMarkPaid error: $e');
      }
    }
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
