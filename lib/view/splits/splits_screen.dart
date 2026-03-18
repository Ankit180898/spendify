import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/groups_controller/groups_controller.dart';
import 'package:spendify/model/group_model.dart';
import 'package:spendify/view/splits/group_detail_screen.dart';

class SplitsScreen extends StatelessWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<GroupsController>()
        ? Get.find<GroupsController>()
        : Get.put(GroupsController(), permanent: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: canPop
            ? IconButton(
                icon: PhosphorIcon(
                  PhosphorIconsLight.arrowLeft,
                  color: textPrimary,
                  size: 20,
                ),
                onPressed: Get.back,
              )
            : null,
        title: Text(
          'Splits',
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _ActionButton(
            icon: PhosphorIconsLight.userPlus,
            label: 'Join',
            isDark: isDark,
            onTap: () => _showJoinSheet(context, ctrl, isDark),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: PhosphorIconsLight.plus,
            label: 'New',
            isDark: isDark,
            isPrimary: true,
            onTap: () => _showCreateSheet(context, ctrl, isDark),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.groups.isEmpty) {
            return _EmptyState(
              isDark: isDark,
              onCreate: () => _showCreateSheet(context, ctrl, isDark),
              onJoin: () => _showJoinSheet(context, ctrl, isDark),
            );
          }
          return RefreshIndicator(
            onRefresh: ctrl.fetchGroups,
            color: AppColor.primary,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              itemCount: ctrl.groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _GroupCard(
                group: ctrl.groups[i],
                isDark: isDark,
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showCreateSheet(BuildContext ctx, GroupsController ctrl, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateGroupSheet(ctrl: ctrl, isDark: isDark),
    );
  }

  void _showJoinSheet(BuildContext ctx, GroupsController ctrl, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinGroupSheet(ctrl: ctrl, isDark: isDark),
    );
  }
}

// ── Group Card ────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final bool isDark;
  const _GroupCard({required this.group, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF9F9F9);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFEEEEEE);
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    return GestureDetector(
      onTap: () => Get.to(() => GroupDetailScreen(group: group)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // Emoji badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(group.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      PhosphorIcon(PhosphorIconsLight.users, size: 12, color: textMuted),
                      const SizedBox(width: 4),
                      Text('${group.members.length} members',
                          style: TextStyle(color: textMuted, fontSize: 12)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColor.darkBorder : const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(group.inviteCode,
                            style: TextStyle(color: textMuted, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PhosphorIcon(PhosphorIconsLight.caretRight, size: 16, color: textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _EmptyState({required this.isDark, required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: PhosphorIcon(PhosphorIconsLight.usersThree, size: 36, color: AppColor.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text('No groups yet', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Create a group for your trip or flat, share the code with friends and split expenses together.',
              style: TextStyle(color: textMuted, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCreate,
                child: const Text('Create a group'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onJoin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  side: const BorderSide(color: AppColor.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Join with a code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Button (header) ────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final bool isDark;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary
        ? AppColor.primary
        : (isDark ? AppColor.darkCard : const Color(0xFFF4F4F5));
    final fg = isPrimary ? Colors.white : (isDark ? AppColor.textPrimary : const Color(0xFF09090B));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Create Group Sheet ────────────────────────────────────────────────────────

class _CreateGroupSheet extends StatefulWidget {
  final GroupsController ctrl;
  final bool isDark;
  const _CreateGroupSheet({required this.ctrl, required this.isDark});

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl = TextEditingController();
  String _emoji = '🧳';
  bool _loading = false;

  static const _emojis = ['🧳', '🏖️', '🏠', '🍽️', '🚗', '🎉', '🏕️', '⚽', '🎬', '🛒', '💼', '🌍'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColor.darkSurface : Colors.white;
    final textPrimary = widget.isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = widget.isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final cardBg = widget.isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? AppColor.darkBorder : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Create a group', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Share the invite code with friends', style: TextStyle(color: textMuted, fontSize: 13)),
          const SizedBox(height: 24),

          // Emoji picker
          Text('Pick an emoji', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((e) => GestureDetector(
              onTap: () => setState(() => _emoji = e),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _emoji == e ? AppColor.primary.withValues(alpha: 0.15) : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _emoji == e ? AppColor.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),

          // Name
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Group name',
              hintText: 'e.g. Bali Trip, Flat expenses',
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create group'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final group = await widget.ctrl.createGroup(_nameCtrl.text, _emoji);
    if (mounted) {
      Navigator.of(context).pop();
      if (group != null) {
        Get.to(() => GroupDetailScreen(group: group));
      }
    }
  }
}

// ── Join Group Sheet ──────────────────────────────────────────────────────────

class _JoinGroupSheet extends StatefulWidget {
  final GroupsController ctrl;
  final bool isDark;
  const _JoinGroupSheet({required this.ctrl, required this.isDark});

  @override
  State<_JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<_JoinGroupSheet> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColor.darkSurface : Colors.white;
    final textPrimary = widget.isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = widget.isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? AppColor.darkBorder : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Join a group', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Ask the group creator for their invite code', style: TextStyle(color: textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          TextField(
            controller: _codeCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 3),
            decoration: const InputDecoration(
              hintText: 'ABC-123',
              hintStyle: TextStyle(letterSpacing: 3),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Join group'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final ok = await widget.ctrl.joinGroup(_codeCtrl.text);
    if (mounted) {
      setState(() => _loading = false);
      if (ok) Navigator.of(context).pop();
    }
  }
}
