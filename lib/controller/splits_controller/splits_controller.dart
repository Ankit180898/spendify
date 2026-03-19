import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/group_model.dart';
import 'package:spendify/model/settlement_model.dart';
import 'package:spendify/model/split_model.dart';
import 'package:spendify/services/notification_service.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class SplitsController extends GetxController {
  final String groupId;
  SplitsController({required this.groupId});

  var splits = <SplitModel>[].obs;
  var members = <GroupMember>[].obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;

  // Set true while GroupDetailScreen is mounted — suppresses notifications
  bool isScreenActive = false;

  // userId -> net balance (positive = they owe you, negative = you owe them)
  var myBalances = <String, double>{}.obs;

  // Simplified debt list for the whole group
  var simplifiedDebts = <DebtEntry>[].obs;

  RealtimeChannel? _channel;
  bool _loadPending = false;

  @override
  void onInit() {
    super.onInit();
    final uid = supabaseC.auth.currentUser?.id;
    if (uid == null) return;
    _load();
    _subscribe();
  }

  @override
  void onClose() {
    _channel?.unsubscribe();
    super.onClose();
  }

  // ── Load ─────────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    isLoading.value = true;
    try {
      await Future.wait([fetchMembers(), fetchSplits()]);
      _recomputeBalances();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _debouncedLoad() async {
    if (_loadPending) return;
    _loadPending = true;
    await Future.delayed(const Duration(milliseconds: 300));
    _loadPending = false;
    await _load();
  }

  Future<void> fetchMembers() async {
    try {
      final res = await supabaseC
          .from('group_members')
          .select()
          .eq('group_id', groupId);
      members.value = res.map((m) => GroupMember.fromMap(m)).toList();
    } catch (e) {
      debugPrint('fetchMembers error: $e');
    }
  }

  Future<void> fetchSplits() async {
    try {
      final res = await supabaseC
          .from('splits')
          .select('*, split_shares(*)')
          .eq('group_id', groupId)
          .order('date', ascending: false);

      splits.value = res.map((m) {
        final split = SplitModel.fromMap(m);
        final sharesRaw = m['split_shares'] as List? ?? [];
        // ✅ Use .value on RxList to trigger reactivity
        split.shares = sharesRaw
            .map((s) => SplitShare.fromMap(s as Map<String, dynamic>))
            .toList();
        return split;
      }).toList();
    } catch (e) {
      debugPrint('fetchSplits error: $e');
    }
  }

  // ── Realtime ──────────────────────────────────────────────────────────────────

  void _subscribe() {
    _channel = supabaseC
        .channel('splits:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'splits',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            _debouncedLoad();
            _notifyNewSplit(payload);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'splits',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) async {
            await fetchSplits();
            _recomputeBalances();
          },
        )
        // split_shares has no group_id but acceptable since scoped per group
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'split_shares',
          callback: (_) async => _debouncedLoad(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'settlements',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) async => _debouncedLoad(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) async {
            await fetchMembers();

            // Local notification when someone else joins this group
            try {
              final uid = supabaseC.auth.currentUser?.id;
              final newUserId = payload.newRecord['user_id'] as String?;
              if (uid == null || newUserId == null || newUserId == uid) return;
              if (isScreenActive) return;

              final memberIndex =
                  members.indexWhere((m) => m.userId == newUserId);
              final name = memberIndex == -1
                  ? 'Someone'
                  : members[memberIndex].displayName;

              await NotificationService.showSplitAlert(
                title: 'New member joined',
                body: '$name just joined this group.',
              );
            } catch (_) {}
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) async {
            // Local notification when someone else leaves this group
            try {
              final uid = supabaseC.auth.currentUser?.id;
              final leftUserId = payload.oldRecord['user_id'] as String?;
              if (uid == null || leftUserId == null || leftUserId == uid) return;
              if (isScreenActive) return;

              final name =
                  (payload.oldRecord['display_name'] as String?) ?? 'Someone';

              await NotificationService.showSplitAlert(
                title: 'Member left',
                body: '$name left this group.',
              );
            } catch (_) {}

            await fetchMembers();
          },
        )
        .subscribe();
  }

  // ── New-split notification (independent of debounce) ─────────────────────────

  Future<void> _notifyNewSplit(PostgresChangePayload payload) async {
    try {
      final uid = supabaseC.auth.currentUser?.id;
      if (uid == null) return;

      final splitId = payload.newRecord['id'] as String?;
      if (splitId == null) return;

      // Wait for split_shares to be written after the splits row
      await Future.delayed(const Duration(milliseconds: 600));

      // Suppress if the user is already viewing this group screen
      if (isScreenActive) return;

      final res = await supabaseC
          .from('splits')
          .select('*, split_shares(*)')
          .eq('id', splitId)
          .single();

      final split = SplitModel.fromMap(res);
      final sharesRaw = res['split_shares'] as List? ?? [];
      split.shares = sharesRaw
          .map((s) => SplitShare.fromMap(s as Map<String, dynamic>))
          .toList();

      final shareIdx = split.shares.indexWhere((sh) => sh.userId == uid);
      final hasShare = shareIdx != -1;

      if (!hasShare && split.paidBy != uid) return;

      if (hasShare) {
        final myShare = split.shares[shareIdx];
        if (myShare.userId != split.paidBy && myShare.amountOwed > 0) {
          await NotificationService.showSplitAlert(
            title: 'You owe in ${split.title}',
            body:
                'You owe ₹${myShare.amountOwed.toStringAsFixed(2)} in this group expense.',
          );
        }
      } else if (split.paidBy == uid) {
        final pendingFromOthers = split.shares
            .where((s) => s.userId != uid && !s.isSettled)
            .fold<double>(0.0, (sum, s) => sum + s.amountOwed);

        if (pendingFromOthers > 0.01) {
          await NotificationService.showSplitAlert(
            title: 'Expense added in ${split.title}',
            body:
                'Others now owe you ₹${pendingFromOthers.toStringAsFixed(2)} for this expense.',
          );
        }
      }
    } catch (_) {}
  }

  // ── Create split ──────────────────────────────────────────────────────────────

  Future<bool> createSplit({
    required String title,
    required double totalAmount,
    required String paidByUserId,
    required String category,
    required DateTime date,
    required Map<String, double> shares,
    String? notes,
  }) async {
    isSubmitting.value = true;
    try {
      final uid = supabaseC.auth.currentUser?.id;
      if (uid == null) return false;

      final dateStr = date.toIso8601String().substring(0, 10);

      final res = await supabaseC
          .from('splits')
          .insert({
            'group_id': groupId,
            'title': title.trim(),
            'total_amount': totalAmount,
            'paid_by': paidByUserId,
            'category': category,
            'date': dateStr,
            'notes': (notes?.trim().isEmpty ?? true) ? null : notes?.trim(),
            'created_by': uid,
          })
          .select()
          .single();

      final splitId = res['id'] as String;

      final shareRows = shares.entries
          .map((e) => {
                'split_id': splitId,
                'user_id': e.key,
                'amount_owed': e.value,
                'is_settled': e.key == paidByUserId,
              })
          .toList();

      await supabaseC.from('split_shares').insert(shareRows);

      if (paidByUserId == uid) {
        final myShare = shares[uid] ?? 0;
        if (myShare > 0) {
          await supabaseC.from('transactions').insert({
            'user_id': uid,
            'amount': myShare,
            'description': title.trim(),
            'type': 'expense',
            'category': category,
            'date': dateStr,
            'source': 'split',
            'split_id': splitId,
          });

          try {
            final homeC = Get.find<HomeController>();
            await homeC.fetchTotalBalanceData();
          } catch (_) {}
        }
      }

      await _load();
      CustomToast.successToast('Added', 'Split added successfully');
      return true;
    } catch (e) {
      debugPrint('createSplit error: $e');
      CustomToast.errorToast('Error', 'Failed to add split');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ── Settle share ──────────────────────────────────────────────────────────────

  Future<void> settleShare({
    required SplitShare share,
    required SplitModel split,
  }) async {
    try {
      final uid = supabaseC.auth.currentUser?.id;
      if (uid == null) return;

      await supabaseC.from('split_shares').update({
        'is_settled': true,
        'settled_at': DateTime.now().toIso8601String(),
      }).eq('id', share.id);

      await supabaseC.from('settlements').insert({
        'group_id': groupId,
        'from_user': share.userId,
        'to_user': split.paidBy,
        'amount': share.amountOwed,
      });

      await fetchSplits();
      _recomputeBalances();

// Transaction for the payer (income)
      if (split.paidBy == uid) {
        final settlerName = _nameOf(share.userId);
        await supabaseC.from('transactions').insert({
          'user_id': uid,
          'amount': share.amountOwed,
          'description': '$settlerName settled "${split.title}"',
          'type': 'income',
          'category': split.category,
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'source': 'settlement',
          'split_id': split.id,
        });
      }

// Transaction for the debtor (expense)
      if (share.userId == uid) {
        final payerName = _nameOf(split.paidBy);
        await supabaseC.from('transactions').insert({
          'user_id': uid,
          'amount': share.amountOwed,
          'description': 'Settled "${split.title}" with $payerName',
          'type': 'expense',
          'category': split.category,
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'source': 'settlement',
          'split_id': split.id,
        });
      }

      try {
        final homeC = Get.find<HomeController>();
        await homeC.fetchTotalBalanceData();
      } catch (_) {}

      CustomToast.successToast('Settled', 'Share marked as settled');
    } catch (e) {
      debugPrint('settleShare error: $e');
      CustomToast.errorToast('Error', 'Failed to settle share');
    }
  }

  // ── Balance computation ───────────────────────────────────────────────────────

  void _recomputeBalances() {
    final uid = supabaseC.auth.currentUser?.id;
    if (uid == null) return;

    final memberIds = {
      ...members.map((m) => m.userId),
      ...splits.expand((s) => [s.paidBy, ...s.shares.map((sh) => sh.userId)]),
    };
    final Map<String, double> net = {for (final id in memberIds) id: 0.0};
    final Map<String, double> my = {};

    for (final split in splits) {
      for (final share in split.shares) {
        if (share.isSettled) continue;
        if (share.userId == split.paidBy) continue;

        net[split.paidBy] = (net[split.paidBy] ?? 0) + share.amountOwed;
        net[share.userId] = (net[share.userId] ?? 0) - share.amountOwed;

        if (split.paidBy == uid) {
          my[share.userId] = (my[share.userId] ?? 0) + share.amountOwed;
        } else if (share.userId == uid) {
          my[split.paidBy] = (my[split.paidBy] ?? 0) - share.amountOwed;
        }
      }
    }

    myBalances.value = my;
    simplifiedDebts.value = _simplifyDebts(net);
  }

  // Greedy O(N²) simplify debts algorithm
  List<DebtEntry> _simplifyDebts(Map<String, double> net) {
    final creditorKeys = net.keys.where((k) => net[k]! > 0.01).toList()
      ..sort((a, b) => net[b]!.compareTo(net[a]!));
    final debtorKeys = net.keys.where((k) => net[k]! < -0.01).toList()
      ..sort((a, b) => net[a]!.compareTo(net[b]!));

    final creditAmts = {for (final k in creditorKeys) k: net[k]!};
    final debtAmts = {for (final k in debtorKeys) k: -net[k]!};

    final result = <DebtEntry>[];
    int i = 0, j = 0;

    while (i < creditorKeys.length && j < debtorKeys.length) {
      if (i >= creditorKeys.length || j >= debtorKeys.length) break;

      final creditor = creditorKeys[i];
      final debtor = debtorKeys[j];
      final settle = min(creditAmts[creditor]!, debtAmts[debtor]!);

      if (settle > 0.01) {
        result.add(DebtEntry(
          fromUserId: debtor,
          fromName: _nameOf(debtor),
          toUserId: creditor,
          toName: _nameOf(creditor),
          amount: settle,
        ));
      }

      creditAmts[creditor] = creditAmts[creditor]! - settle;
      debtAmts[debtor] = debtAmts[debtor]! - settle;

      if (creditAmts[creditor]! < 0.01) i++;
      if (debtAmts[debtor]! < 0.01) j++;
    }

    return result;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _nameOf(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId).displayName;
    } catch (_) {
      return 'Member';
    }
  }

  String nameOf(String userId) => _nameOf(userId);

  double myTotalOwed() =>
      myBalances.values.where((v) => v < 0).fold(0.0, (s, v) => s + v.abs());

  double totalOwedToMe() =>
      myBalances.values.where((v) => v > 0).fold(0.0, (s, v) => s + v);
}
