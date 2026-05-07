import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/groups_controller/groups_controller.dart';
import 'package:spendify/model/group_model.dart';
import 'package:spendify/view/splits/group_detail_screen.dart';

Color _groupAccent(String emoji) {
  const map = {
    '🧳': Color(0xFF4BAFD6),
    '🏖️': Color(0xFFF5A623),
    '🏠': Color(0xFF6B5BFF),
    '🍽️': Color(0xFFFF5370),
    '🚗': Color(0xFF26D0A0),
    '🎉': Color(0xFFFF4081),
    '🏕️': Color(0xFF43A047),
    '⚽': Color(0xFF26D0A0),
    '🎬': Color(0xFF7E57C2),
    '🛒': Color(0xFFF5A623),
    '💼': Color(0xFF546E7A),
    '🌍': Color(0xFF00C896),
    '✈️': Color(0xFF4BAFD6),
    '🍕': Color(0xFFFF5370),
    '🎵': Color(0xFF7E57C2),
    '🏋️': Color(0xFF26D0A0),
  };
  return map[emoji] ?? const Color(0xFF6B5BFF);
}

class SplitsScreen extends StatelessWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<GroupsController>()
        ? Get.find<GroupsController>()
        : Get.put(GroupsController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColor.bg,
      appBar: AppBar(
        backgroundColor: AppColor.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const PhosphorIcon(
                  PhosphorIconsLight.arrowLeft,
                  color: AppColor.textPrimary,
                  size: 20,
                ),
                onPressed: Get.back,
              )
            : null,
        title: Text(
          'Splits',
          style: GoogleFonts.urbanist(
            color: AppColor.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          _AppBarBtn(
            label: 'Join',
            onTap: () => _showJoinSheet(context, ctrl),
          ),
          const SizedBox(width: 8),
          _AppBarBtn(
            label: 'New group',
            filled: true,
            onTap: () => _showCreateSheet(context, ctrl),
          ),
          const SizedBox(width: 16),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColor.border),
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
              onCreate: () => _showCreateSheet(context, ctrl),
              onJoin: () => _showJoinSheet(context, ctrl),
            );
          }
          return RefreshIndicator(
            onRefresh: ctrl.fetchGroups,
            color: AppColor.primary,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              itemCount: ctrl.groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _GroupCard(group: ctrl.groups[i]),
            ),
          );
        }),
      ),
    );
  }

  void _showCreateSheet(BuildContext ctx, GroupsController ctrl) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateGroupSheet(ctrl: ctrl),
    );
  }

  void _showJoinSheet(BuildContext ctx, GroupsController ctrl) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinGroupSheet(ctrl: ctrl),
    );
  }
}

// ── App Bar Button ─────────────────────────────────────────────────────────────

class _AppBarBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _AppBarBtn({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: filled ? null : Border.all(color: AppColor.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            color: filled ? Colors.white : AppColor.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Group Card ─────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final accent = _groupAccent(group.emoji);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.to(() => GroupDetailScreen(group: group));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  group.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: GoogleFonts.urbanist(
                      color: AppColor.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MemberAvatarStack(members: group.members),
                      const SizedBox(width: 8),
                      Text(
                        '${group.members.length} member${group.members.length == 1 ? '' : 's'}',
                        style: GoogleFonts.urbanist(
                          color: AppColor.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const PhosphorIcon(
              PhosphorIconsLight.caretRight,
              size: 16,
              color: AppColor.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member Avatar Stack ────────────────────────────────────────────────────────

class _MemberAvatarStack extends StatelessWidget {
  final List<GroupMember> members;
  const _MemberAvatarStack({required this.members});

  static const _colors = [
    Color(0xFF6B5BFF),
    Color(0xFF00C896),
    Color(0xFFF5A623),
    Color(0xFFFF5370),
  ];

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    const shift = 13.0;
    final shown = members.take(4).toList();
    final count = shown.length;
    if (count == 0) return const SizedBox.shrink();

    return SizedBox(
      width: size + (count - 1) * shift,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              left: i * shift,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _colors[i % _colors.length],
                  border: Border.all(color: AppColor.surface, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    shown[i].displayName.isNotEmpty
                        ? shown[i].displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.urbanist(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _EmptyState({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColor.primaryExtraSoft,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: PhosphorIcon(
                  PhosphorIconsLight.usersThree,
                  size: 32,
                  color: AppColor.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No groups yet',
              style: GoogleFonts.urbanist(
                color: AppColor.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group for your trip, flat, or friends — then split expenses together.',
              style: GoogleFonts.urbanist(
                color: AppColor.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
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
                  side: const BorderSide(color: AppColor.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Join with a code',
                  style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Group Sheet ─────────────────────────────────────────────────────────

class _CreateGroupSheet extends StatefulWidget {
  final GroupsController ctrl;
  const _CreateGroupSheet({required this.ctrl});

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl = TextEditingController();
  String _emoji = '🧳';
  bool _loading = false;

  static const _emojis = [
    '🧳', '🏖️', '🏠', '🍽️', '🚗', '🎉',
    '🏕️', '⚽', '🎬', '🛒', '💼', '🌍',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Create a group',
            style: GoogleFonts.urbanist(
              color: AppColor.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share the invite code with friends',
            style: GoogleFonts.urbanist(
              color: AppColor.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Pick an emoji',
            style: GoogleFonts.urbanist(
              color: AppColor.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis
                .map((e) => GestureDetector(
                      onTap: () => setState(() => _emoji = e),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _emoji == e
                              ? AppColor.primary.withValues(alpha: 0.1)
                              : AppColor.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _emoji == e
                                ? AppColor.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            e,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
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

// ── Join Group Sheet ───────────────────────────────────────────────────────────

class _JoinGroupSheet extends StatefulWidget {
  final GroupsController ctrl;
  const _JoinGroupSheet({required this.ctrl});

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
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Join a group',
            style: GoogleFonts.urbanist(
              color: AppColor.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask the group creator for their invite code',
            style: GoogleFonts.urbanist(
              color: AppColor.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
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
