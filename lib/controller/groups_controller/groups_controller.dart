import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/group_model.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class GroupsController extends GetxController {
  var groups = <GroupModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    isLoading.value = true;
    try {
      final uid = supabaseC.auth.currentUser?.id;
      if (uid == null) return;

      // ✅ Single join query instead of two separate queries
      final response = await supabaseC
          .from('group_members')
          .select('group_id, groups(*)')
          .eq('user_id', uid);

      if (response.isEmpty) {
        groups.value = [];
        return;
      }

      final groupIds = response.map((m) => m['group_id'] as String).toList();

      final fetched = response
          .map((m) => GroupModel.fromMap(m['groups'] as Map<String, dynamic>))
          .toList();

      // ✅ Single batched query for all members instead of N+1 loop
      final allMembers = await supabaseC
          .from('group_members')
          .select()
          .inFilter('group_id', groupIds);

      for (final group in fetched) {
        group.members = allMembers
            .where((m) => m['group_id'] == group.id)
            .map((m) => GroupMember.fromMap(m))
            .toList();
      }

      // Sort by created_at descending
      fetched.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      groups.value = fetched;
    } catch (e) {
      debugPrint('GroupsController.fetchGroups error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<GroupModel?> createGroup(String name, String emoji) async {
    try {
      final uid = supabaseC.auth.currentUser?.id;
      if (uid == null) return null;

      final code = await _generateUniqueCode();

      final res = await supabaseC
          .from('groups')
          .insert({
            'name': name.trim(),
            'emoji': emoji,
            'invite_code': code,
            'created_by': uid,
          })
          .select()
          .single();

      final group = GroupModel.fromMap(res);

      final displayName = await _getDisplayName(uid);
      await supabaseC.from('group_members').insert({
        'group_id': group.id,
        'user_id': uid,
        'display_name': displayName,
      });

      await fetchGroups();
      return group;
    } catch (e) {
      debugPrint('GroupsController.createGroup error: $e');
      CustomToast.errorToast('Error', 'Failed to create group');
      return null;
    }
  }

  Future<bool> joinGroup(String code) async {
    try {
      final uid = supabaseC.auth.currentUser?.id;
      if (uid == null) return false;

      final res = await supabaseC
          .from('groups')
          .select()
          .eq('invite_code', code.toUpperCase().trim())
          .maybeSingle();

      if (res == null) {
        CustomToast.errorToast('Invalid code', 'No group found with this code');
        return false;
      }

      final groupId = res['id'] as String;
      final displayName = await _getDisplayName(uid);

      try {
        // ✅ Use unique constraint + catch duplicate instead of pre-check query
        await supabaseC.from('group_members').insert({
          'group_id': groupId,
          'user_id': uid,
          'display_name': displayName,
        });
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('duplicate') ||
            msg.contains('23505') ||
            msg.contains('unique')) {
          CustomToast.errorToast(
              'Already joined', 'You are already in this group');
          return false;
        }
        rethrow;
      }

      await fetchGroups();
      CustomToast.successToast('Joined!', 'Welcome to ${res['name']}');
      return true;
    } catch (e) {
      debugPrint('GroupsController.joinGroup error: $e');
      CustomToast.errorToast('Error', 'Failed to join group');
      return false;
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      final uid = supabaseC.auth.currentUser?.id;
      if (uid == null) return;

      // Prevent leaving if there are unsettled balances in this group
      final dues = await supabaseC
          .from('split_shares')
          .select('amount_owed, is_settled, splits!inner(group_id, paid_by)')
          .eq('user_id', uid)
          .eq('splits.group_id', groupId);

      double net = 0.0;
      for (final row in dues) {
        if (row['is_settled'] == true) continue;
        final amt = (row['amount_owed'] as num?)?.toDouble() ?? 0.0;
        final paidBy = row['splits']['paid_by'] as String?;
        if (amt <= 0 || paidBy == null) continue;

        if (paidBy == uid) {
          // Others owe me
          net += amt;
        } else {
          // I owe someone else
          net -= amt;
        }
      }

      if (net.abs() > 0.01) {
        CustomToast.errorToast(
          'Cannot leave',
          'You still have unsettled balances in this group.',
        );
        return;
      }

      await supabaseC
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', uid);

      groups.removeWhere((g) => g.id == groupId);
      CustomToast.successToast('Left group', 'You have left the group');
    } catch (e) {
      debugPrint('GroupsController.leaveGroup error: $e');
      CustomToast.errorToast('Error', 'Failed to leave group');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Future<String> _getDisplayName(String uid) async {
    try {
      final res = await supabaseC
          .from('users')
          .select('name')
          .eq('id', uid)
          .maybeSingle();
      return (res?['name'] as String?) ?? 'Member';
    } catch (_) {
      return 'Member';
    }
  }

  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();

    String code;
    bool exists;
    do {
      final p1 =
          List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
      final p2 =
          List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
      code = '$p1-$p2';

      final res = await supabaseC
          .from('groups')
          .select('id')
          .eq('invite_code', code)
          .maybeSingle();
      exists = res != null;
    } while (exists);

    return code;
  }
}
