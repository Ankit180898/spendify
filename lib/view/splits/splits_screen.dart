import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/groups_controller/groups_controller.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/model/group_model.dart';
import 'package:spendify/view/splits/group_detail_screen.dart';

Color _groupAccent(String emoji) {
  const map = {
    '🧳': Color(0xFF6E8CA8),
    '🏖️': Color(0xFFD99A4E),
    '🏠': Color(0xFF9A7BB5),
    '🍽️': Color(0xFFCB5F55),
    '🚗': Color(0xFF5E8F8A),
    '🎉': Color(0xFFC46A86),
    '🏕️': Color(0xFF6B8F5A),
    '⚽': Color(0xFF5E8F8A),
    '🎬': Color(0xFF8C6FA8),
    '🛒': Color(0xFFD99A4E),
    '💼': Color(0xFF7A6E66),
    '🌍': Color(0xFF4F9A74),
    '✈️': Color(0xFF6E8CA8),
    '🍕': Color(0xFFCB5F55),
    '🎵': Color(0xFF8C6FA8),
    '🏋️': Color(0xFF5E8F8A),
  };
  return map[emoji] ?? const Color(0xFF9A7BB5);
}

class SplitsScreen extends StatelessWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<GroupsController>()
        ? Get.find<GroupsController>()
        : Get.put(GroupsController(), permanent: true);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(canPop ? 6 : 20, 10, 16, 0),
              child: Row(
                children: [
                  if (canPop)
                    IconButton(
                      onPressed: Get.back,
                      icon: const PhosphorIcon(PhosphorIconsLight.arrowLeft,
                          color: AppColor.textPrimary, size: 22),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Splits',
                          style: GoogleFonts.urbanist(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        Text(
                          'Share costs, settle up, stay friends',
                          style: GoogleFonts.urbanist(fontSize: 13, color: AppColor.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _AppBarBtn(label: 'Join', onTap: () => _showJoinSheet(context, ctrl)),
                  const SizedBox(width: 8),
                  _AppBarBtn(
                    label: 'New',
                    icon: PhosphorIconsBold.plus,
                    filled: true,
                    onTap: () => _showCreateSheet(context, ctrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value && ctrl.groups.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColor.primary));
                }
                if (ctrl.groups.isEmpty) {
                  return _EmptyState(
                    onCreate: () => _showCreateSheet(context, ctrl),
                    onJoin: () => _showJoinSheet(context, ctrl),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await ctrl.fetchGroups();
                    await ctrl.fetchBalanceSummary();
                  },
                  color: AppColor.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    children: [
                      _BalanceSummary(ctrl: ctrl),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
                        child: Row(
                          children: [
                            Text(
                              'Your groups',
                              style: GoogleFonts.urbanist(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColor.heading,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${ctrl.groups.length}',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                color: AppColor.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (var i = 0; i < ctrl.groups.length; i++) ...[
                        _GroupCard(group: ctrl.groups[i], index: i),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
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

// ── Balance summary ────────────────────────────────────────────────────────────

class _BalanceSummary extends StatelessWidget {
  final GroupsController ctrl;
  const _BalanceSummary({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final sym = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().currencySymbol.value
        : '₹';

    return Obx(() {
      final owe = ctrl.totalOwed.value;
      final owed = ctrl.totalOwedToMe.value;
      final net = owed - owe;
      final settled = owe == 0 && owed == 0;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.bannerBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settled ? 'All settled up' : net >= 0 ? 'Overall, you\'re owed' : 'Overall, you owe',
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settled ? 'Nice and even' : '$sym${fmt.format(net.abs())}',
                        style: GoogleFonts.urbanist(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: settled
                              ? AppColor.textPrimary
                              : net >= 0
                                  ? AppColor.income
                                  : AppColor.expense,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColor.surface.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      settled ? PhosphorIconsDuotone.handshake : PhosphorIconsDuotone.usersThree,
                      size: 26,
                      color: settled ? AppColor.income : AppColor.primary,
                      duotoneSecondaryOpacity: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            if (!settled) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _OweTile(
                      label: 'You owe',
                      value: '$sym${fmt.format(owe)}',
                      icon: PhosphorIconsDuotone.arrowUpRight,
                      color: AppColor.expense,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OweTile(
                      label: 'You\'re owed',
                      value: '$sym${fmt.format(owed)}',
                      icon: PhosphorIconsDuotone.arrowDownLeft,
                      color: AppColor.income,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _OweTile extends StatelessWidget {
  final String label;
  final String value;
  final Object icon;
  final Color color;
  const _OweTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: PhosphorIcon(icon, size: 14, color: color, duotoneSecondaryOpacity: 0.3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.urbanist(fontSize: 11, color: AppColor.textTertiary)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── App Bar Button ─────────────────────────────────────────────────────────────

class _AppBarBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final PhosphorIconData? icon;
  final VoidCallback onTap;

  const _AppBarBtn({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColor.primary : AppColor.surface,
          borderRadius: BorderRadius.circular(100),
          border: filled ? null : Border.all(color: AppColor.borderStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              PhosphorIcon(icon!, size: 13, color: filled ? Colors.white : AppColor.textPrimary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.urbanist(
                color: filled ? Colors.white : AppColor.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Group Card ─────────────────────────────────────────────────────────────────

class _GroupCard extends StatefulWidget {
  final GroupModel group;
  final int index;
  const _GroupCard({required this.group, this.index = 0});

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final accent = _groupAccent(group.emoji);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + widget.index * 60),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.lightImpact();
          Get.to(() => GroupDetailScreen(group: group), transition: Transition.cupertino);
        },
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColor.borderStrong),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Text(group.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          color: AppColor.textPrimary,
                          fontSize: 16,
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColor.primaryExtraSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: PhosphorIcon(PhosphorIconsBold.caretRight,
                        size: 13, color: AppColor.primary),
                  ),
                ),
              ],
            ),
          ),
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
    Color(0xFF86695B),
    Color(0xFF4F9A74),
    Color(0xFFD99A4E),
    Color(0xFF6E8CA8),
  ];

  @override
  Widget build(BuildContext context) {
    const size = 22.0;
    const shift = 14.0;
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
                      fontSize: 9,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 120),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColor.primaryExtraSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColor.borderStrong, width: 1.5),
              ),
              child: const Center(
                child: PhosphorIcon(
                  PhosphorIconsDuotone.usersThree,
                  size: 44,
                  color: AppColor.primary,
                  duotoneSecondaryOpacity: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Split costs with friends',
            style: GoogleFonts.urbanist(
              color: AppColor.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make a group for a trip, your flat or a dinner — add what you paid and Spendify works out who owes whom.',
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
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 15, color: Colors.white),
              label: const Text('Create a group'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onJoin,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.textPrimary,
                side: const BorderSide(color: AppColor.borderStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                'Join with a code',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
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
