import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spendify/main.dart';
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

  // In-memory sets populated from Supabase at scan time
  final Set<String> _importedHashes = {};
  final Set<String> _importedTxKeys = {};

  @override
  void onClose() {
    detectedTransactions.clear();
    _importedHashes.clear();
    _importedTxKeys.clear();
    super.onClose();
  }

  Future<void> _loadImportedData() async {
    final uid = supabaseC.auth.currentUser?.id;
    if (uid == null) return;

    _importedHashes.clear();
    _importedTxKeys.clear();

    final rows = await supabaseC
        .from('sms_imported_hashes')
        .select('sms_hash, tx_key')
        .eq('user_id', uid);

    for (final row in rows) {
      if (row['sms_hash'] != null) _importedHashes.add(row['sms_hash'] as String);
      if (row['tx_key'] != null) _importedTxKeys.add(row['tx_key'] as String);
    }
  }

  Future<void> markAsImported(List<SmsTransaction> imported) async {
    final uid = supabaseC.auth.currentUser?.id;
    if (uid == null) return;

    final newRows = <Map<String, dynamic>>[];
    for (final tx in imported) {
      final hash = _hashOf(tx.rawMessage);
      final key = _txKeyOf(tx);

      // Skip rows we already know about to avoid duplicates
      if (_importedHashes.contains(hash)) continue;

      _importedHashes.add(hash);
      _importedTxKeys.add(key);
      newRows.add({
        'user_id': uid,
        'sms_hash': hash,
        'tx_key': key,
      });
    }

    if (newRows.isNotEmpty) {
      await supabaseC.from('sms_imported_hashes').insert(newRows);
    }
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
      final status = await Permission.sms.request();
      if (!status.isGranted) {
        hasPermission.value = false;
        errorMessage.value =
            'SMS permission denied. Please allow SMS access in Settings.';
        return;
      }
      hasPermission.value = true;

      // Load imported hashes fresh from Supabase each scan
      await _loadImportedData();

      final cutoff =
          DateTime.now().subtract(const Duration(days: _scanDays));

      final query = SmsQuery();
      // Use a high count — some devices return oldest-first so a low limit
      // would miss recent messages.
      final messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 2000,
      );

      // Matches common Indian bank sender IDs (VM-SBIINB, AX-STATEBANK, BZ-HDFCBK, etc.)
      final financialSenders = RegExp(
        r'(hdfc|sbi|icici|axis|kotak|pnb|bob|canara|union|indus|'
        r'rbl|idfc|federal|bandhan|paytm|phonepe|gpay|bhim|upi|'
        r'amex|citibank|hsbc|dbs|swiggy|zomato|amazon|flipkart|'
        r'statebank|sbiyono|vijaya|uco|allahabad|obc|central|dena|'
        r'syndicate|andhra|corporation|indian bank|iob|boi|maharashtra|'
        r'neft|imps|rtgs|nach|mandate)',
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
        final lower = body.toLowerCase();
        final isFinancial = financialSenders.hasMatch(address) ||
            financialSenders.hasMatch(body) ||
            lower.contains('debited') ||
            lower.contains('credited') ||
            lower.contains('debit') ||
            lower.contains('credit') ||
            lower.contains('rs.') ||
            lower.contains('rs ') ||
            lower.contains('inr') ||
            lower.contains('₹') ||
            lower.contains('txn') ||
            lower.contains('transaction') ||
            lower.contains('transferred') ||
            lower.contains('payment of') ||
            lower.contains('paid') ||
            lower.contains('a/c') ||
            lower.contains('acct') ||
            lower.contains('withdrawn') ||
            lower.contains('purchase');

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
