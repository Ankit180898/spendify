import 'dart:io';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spendify/services/sms_parser_service.dart';

class SmsController extends GetxController {
  final detectedTransactions = <SmsTransaction>[].obs;
  final isLoading = false.obs;
  final hasPermission = false.obs;
  final errorMessage = ''.obs;

  // How far back to scan (days)
  static const _scanDays = 30;

  Future<void> scanSms() async {
    if (!Platform.isAndroid) {
      errorMessage.value = 'SMS scanning is only available on Android.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    detectedTransactions.clear();

    try {
      final status = await Permission.sms.request();
      if (!status.isGranted) {
        hasPermission.value = false;
        errorMessage.value =
            'SMS permission denied. Please allow SMS access in Settings.';
        return;
      }
      hasPermission.value = true;

      final query = SmsQuery();
      final messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
      );

      // Filter to last N days and known financial senders
      final cutoff = DateTime.now().subtract(const Duration(days: _scanDays));
      final financialSenders = RegExp(
        r'(hdfc|sbi|icici|axis|kotak|pnb|bob|canara|union|indus|yes bank|'
        r'rbl|idfc|au bank|federal|bandhan|paytm|phonepe|gpay|bhim|upi|'
        r'amex|citibank|hsbc|dbs|swiggy|zomato|amazon|flipkart)',
        caseSensitive: false,
      );

      final filtered = messages.where((m) {
        final body = m.body ?? '';
        final address = m.address ?? '';
        final date = m.date;
        if (date != null && date.isBefore(cutoff)) { return false; }
        return financialSenders.hasMatch(address) ||
            financialSenders.hasMatch(body) ||
            body.toLowerCase().contains('debited') ||
            body.toLowerCase().contains('credited') ||
            body.toLowerCase().contains('rs.') ||
            body.toLowerCase().contains('inr');
      }).toList();

      final rawMessages = filtered.map((m) => m.body ?? '').toList();
      final parsed = SmsParserService.parseAll(rawMessages);

      detectedTransactions.assignAll(parsed);

      if (parsed.isEmpty) {
        errorMessage.value =
            'No transactions found in the last $_scanDays days.';
      }
    } catch (e) {
      errorMessage.value = 'Failed to read SMS: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSelection(int index) {
    if (index < 0 || index >= detectedTransactions.length) { return; }
    detectedTransactions[index].isSelected =
        !detectedTransactions[index].isSelected;
    detectedTransactions.refresh();
  }

  void selectAll() {
    for (final tx in detectedTransactions) {
      tx.isSelected = true;
    }
    detectedTransactions.refresh();
  }

  void deselectAll() {
    for (final tx in detectedTransactions) {
      tx.isSelected = false;
    }
    detectedTransactions.refresh();
  }

  int get selectedCount =>
      detectedTransactions.where((t) => t.isSelected).length;
}
