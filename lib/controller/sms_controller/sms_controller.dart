import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/services/sms_parser_service.dart';

// Wrapper so we can carry the raw SMS timestamp into the isolate alongside the body
class _SmsPayload {
  final String body;
  final String sender; // SMS address/sender ID e.g. "VM-HDFCBK"
  final int timestampMs;

  const _SmsPayload({required this.body, required this.sender, required this.timestampMs});
}

List<SmsTransaction> _parseInIsolate(List<_SmsPayload> payloads) {
  final results = <SmsTransaction>[];
  for (final p in payloads) {
    final parsed = SmsParserService.parseAll([p.body], sender: p.sender);
    for (final tx in parsed) {
      results.add(SmsTransaction(
        rawMessage: tx.rawMessage,
        amount: tx.amount,
        type: tx.type,
        merchant: tx.merchant,
        category: tx.category,
        date: DateTime.fromMillisecondsSinceEpoch(p.timestampMs),
        isSelected: tx.isSelected,
      ));
    }
  }
  return results;
}

class SmsController extends GetxController {
  final detectedTransactions = <SmsTransaction>[].obs;
  final isLoading = false.obs;
  final hasPermission = false.obs;
  final errorMessage = ''.obs;

  static const _scanDays = 30;
  static const _prefKeyHashes = 'sms_imported_hashes';
  static const _prefKeyTxKeys = 'sms_imported_tx_keys';

  // Raw-message hashes (exact match)
  final Set<String> _importedHashes = {};
  // Semantic keys: amount|merchant|date — catches different SMS text for the same transaction
  final Set<String> _importedTxKeys = {};

  late final Future<void> _dataReady;

  @override
  void onInit() {
    super.onInit();
    _dataReady = _loadImportedData();
  }

  @override
  void onClose() {
    detectedTransactions.clear();
    _importedHashes.clear();
    _importedTxKeys.clear();
    super.onClose();
  }

  Future<void> _loadImportedData() async {
    final prefs = await SharedPreferences.getInstance();
    _importedHashes.addAll(prefs.getStringList(_prefKeyHashes) ?? []);
    _importedTxKeys.addAll(prefs.getStringList(_prefKeyTxKeys) ?? []);
  }

  Future<void> markAsImported(List<SmsTransaction> imported) async {
    for (final tx in imported) {
      _importedHashes.add(_hashOf(tx.rawMessage));
      _importedTxKeys.add(_txKeyOf(tx));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKeyHashes, _importedHashes.toList());
    await prefs.setStringList(_prefKeyTxKeys, _importedTxKeys.toList());
  }

  /// Remove successfully imported transactions from the visible list immediately,
  /// so the user cannot accidentally import them again in the same session.
  void removeImported(List<SmsTransaction> imported) {
    final importedRaws = imported.map((tx) => tx.rawMessage).toSet();
    detectedTransactions
        .removeWhere((tx) => importedRaws.contains(tx.rawMessage));
  }

  static String _hashOf(String raw) {
    final trimmed = raw.trim();
    final prefix = trimmed.substring(0, trimmed.length.clamp(0, 120));
    return base64.encode(utf8.encode(prefix));
  }

  // amount|merchant(lowercase)|yyyyMMdd — stable key across different SMS wordings
  static String _txKeyOf(SmsTransaction tx) {
    final d = tx.date;
    final dateStr =
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    return '${tx.amount}|${tx.merchant.toLowerCase().trim()}|$dateStr';
  }

  Future<void> scanSms() async {
    if (!Platform.isAndroid) {
      errorMessage.value = 'SMS scanning is only available on Android.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    detectedTransactions.clear();

    try {
      await _dataReady; // ensure imported data is loaded before filtering
      final status = await Permission.sms.request();
      if (!status.isGranted) {
        hasPermission.value = false;
        errorMessage.value =
            'SMS permission denied. Please allow SMS access in Settings.';
        return;
      }
      hasPermission.value = true;

      final cutoff =
          DateTime.now().subtract(const Duration(days: _scanDays));

      final query = SmsQuery();
      final messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
      );

      final financialSenders = RegExp(
        r'(hdfc|sbi|icici|axis|kotak|pnb|bob|canara|union|indus|yes bank|'
        r'rbl|idfc|au bank|federal|bandhan|paytm|phonepe|gpay|bhim|upi|'
        r'amex|citibank|hsbc|dbs|swiggy|zomato|amazon|flipkart)',
        caseSensitive: false,
      );

      // Stage 1: raw message filter — skip messages whose exact text was already imported
      final payloads = <_SmsPayload>[];
      for (final m in messages) {
        final body = m.body ?? '';
        if (body.isEmpty) continue;

        final msgDate = m.date;
        if (msgDate != null && msgDate.isBefore(cutoff)) continue;
        if (_importedHashes.contains(_hashOf(body))) continue;

        final address = m.address ?? '';
        final isFinancial = financialSenders.hasMatch(address) ||
            financialSenders.hasMatch(body) ||
            body.toLowerCase().contains('debited') ||
            body.toLowerCase().contains('credited') ||
            body.toLowerCase().contains('rs.') ||
            body.toLowerCase().contains('inr');

        if (isFinancial) {
          payloads.add(_SmsPayload(
            body: body,
            sender: address,
            timestampMs: msgDate?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
          ));
        }
      }

      // Parse off the main thread, now carrying real timestamps
      final parsed = await compute(_parseInIsolate, payloads);

      // Stage 2: semantic filter — skip transactions matching amount+merchant+date
      // of already-imported ones.
      final filtered = parsed
          .where((tx) => !_importedTxKeys.contains(_txKeyOf(tx)))
          .toList();

      // Sort newest → oldest using the full SMS timestamp (hour/minute precision)
      filtered.sort((a, b) => b.date.compareTo(a.date));

      detectedTransactions.assignAll(filtered);

      if (filtered.isEmpty) {
        errorMessage.value =
            'No new transactions found in the last $_scanDays days.';
      }
    } catch (e) {
      errorMessage.value = 'Failed to read SMS: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSelection(int index) {
    if (index < 0 || index >= detectedTransactions.length) return;
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