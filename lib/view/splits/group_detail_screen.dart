import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/groups_controller/groups_controller.dart';
import 'package:spendify/controller/splits_controller/splits_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/group_model.dart';
import 'package:spendify/model/split_model.dart';
import 'package:spendify/view/splits/add_split_screen.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

// Maps an emoji to a distinctive accent color for the group theme.
Color _emojiAccent(String emoji) {
  const map = {
    '🧳': Color(0xFF4BAFD6), // travel blue
    '🏖️': Color(0xFFF5A623), // beach amber
    '🏠': Color(0xFF6B5BFF), // home purple
    '🍽️': Color(0xFFFF5370), // food red
    '🚗': Color(0xFF26D0A0), // car teal
    '🎉': Color(0xFFFF4081), // party pink
    '🏕️': Color(0xFF43A047), // camping green
    '⚽': Color(0xFF26D0A0), // sport teal
    '🎬': Color(0xFF7E57C2), // cinema purple
    '🛒': Color(0xFFF5A623), // shopping amber
    '💼': Color(0xFF546E7A), // work slate
    '🌍': Color(0xFF00C896), // globe green
    '✈️': Color(0xFF4BAFD6), // flight blue
    '🍕': Color(0xFFFF5370), // pizza red
    '🎵': Color(0xFF7E57C2), // music purple
    '🏋️': Color(0xFF26D0A0), // gym teal
  };
  return map[emoji] ?? const Color(0xFF6B5BFF);
}

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late final SplitsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(
      SplitsController(groupId: widget.group.id),
      tag: widget.group.id,
    );
    _ctrl.isScreenActive = true;
  }

  @override
  void dispose() {
    _ctrl.isScreenActive = false;
    Get.delete<SplitsController>(tag: widget.group.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = supabaseC.auth.currentUser?.id ?? '';
    final accent = _emojiAccent(widget.group.emoji);

    return Scaffold(
      backgroundColor: AppColor.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Color.lerp(AppColor.surface, accent, 0.06),
            elevation: 0,
            pinned: true,
            titleSpacing: 0,
            leading: IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsLight.caretLeft,
                color: AppColor.textPrimary,
                size: 20,
              ),
              onPressed: Get.back,
            ),
            title: Row(
              children: [
                Text(widget.group.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.group.name,
                    style: GoogleFonts.urbanist(
                      color: AppColor.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: widget.group.inviteCode));
                  CustomToast.successToast('Copied!', 'Invite code copied');
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.group.inviteCode,
                        style: GoogleFonts.urbanist(
                          color: accent.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      PhosphorIcon(
                        PhosphorIconsLight.copySimple,
                        size: 10,
                        color: accent.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const PhosphorIcon(
                  PhosphorIconsLight.doorOpen,
                  color: AppColor.textSecondary,
                  size: 20,
                ),
                onPressed: () => _confirmLeave(context),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColor.border),
            ),
          ),

          // ── Members strip ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Obx(() => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _MemberAvatarRow(members: _ctrl.members.toList()),
                )),
          ),

          // ── Loading ──────────────────────────────────────────────────────────
          Obx(() {
            if (_ctrl.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }),

          // ── Balance section ──────────────────────────────────────────────────
          Obx(() {
            if (_ctrl.isLoading.value) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverToBoxAdapter(
              child: _BalanceSection(ctrl: _ctrl, myUid: myUid),
            );
          }),

          // ── Expenses header ──────────────────────────────────────────────────
          Obx(() => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Expenses',
                        style: GoogleFonts.urbanist(
                          color: AppColor.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (_ctrl.splits.isNotEmpty)
                        Text(
                          '${_ctrl.splits.length} total',
                          style: GoogleFonts.urbanist(
                            color: AppColor.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              )),

          // ── Expense list (date-grouped) ──────────────────────────────────────
          Obx(() {
            if (_ctrl.isLoading.value) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            if (_ctrl.splits.isEmpty) {
              return SliverToBoxAdapter(child: _EmptySplits());
            }

            final splits = _ctrl.splits;
            final items = <_ListItem>[];
            String? lastMonth;

            for (int i = 0; i < splits.length; i++) {
              final monthKey =
                  DateFormat('MMMM yyyy').format(splits[i].date);
              if (monthKey != lastMonth) {
                items.add(_ListItem.header(monthKey));
                lastMonth = monthKey;
              }
              items.add(_ListItem.tile(i));
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final item = items[i];
                  if (item.isHeader) {
                    return _MonthHeader(month: item.monthKey!);
                  }
                  return _SplitTile(
                    key: ValueKey(_ctrl.splits[item.index!].id),
                    index: item.index!,
                    ctrl: _ctrl,
                    myUid: myUid,
                  );
                },
                childCount: items.length,
              ),
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(
          () => AddSplitScreen(ctrl: _ctrl),
          transition: Transition.cupertino,
        ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        icon: const PhosphorIcon(PhosphorIconsLight.plus, size: 18),
        label: Text(
          'Add expense',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        decoration: const BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColor.expense.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: PhosphorIcon(
                  PhosphorIconsLight.doorOpen,
                  color: AppColor.expense,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Leave group?',
              style: GoogleFonts.urbanist(
                color: AppColor.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will lose access to all splits in "${widget.group.name}". Unsettled balances will remain.',
              style: GoogleFonts.urbanist(
                color: AppColor.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    final gc = Get.find<GroupsController>();
                    await gc.leaveGroup(widget.group.id);
                  } catch (_) {}
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.expense,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Leave group',
                  style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.urbanist(
                    color: AppColor.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── List item model (header vs tile) ──────────────────────────────────────────

class _ListItem {
  final bool isHeader;
  final String? monthKey;
  final int? index;

  const _ListItem.header(String month)
      : isHeader = true,
        monthKey = month,
        index = null;

  const _ListItem.tile(int i)
      : isHeader = false,
        monthKey = null,
        index = i;
}

// ── Member avatar row (header) ────────────────────────────────────────────────

class _MemberAvatarRow extends StatelessWidget {
  final List<GroupMember> members;
  const _MemberAvatarRow({required this.members});

  static const _colors = [
    Color(0xFF6B5BFF),
    Color(0xFF00C896),
    Color(0xFFF5A623),
    Color(0xFFFF5370),
    Color(0xFF4BAFD6),
  ];

  @override
  Widget build(BuildContext context) {
    const size = 22.0;
    const shift = 15.0;
    final shown = members.take(5).toList();
    final extra = members.length - shown.length;

    if (shown.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: size,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: size + (shown.length - 1) * shift,
            height: size,
            child: Stack(
              children: [
                for (int i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * shift,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _colors[i % _colors.length],
                        border:
                            Border.all(color: AppColor.surface, width: 1.5),
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
          ),
          if (extra > 0) ...[
            const SizedBox(width: 6),
            Text(
              '+$extra more',
              style: GoogleFonts.urbanist(
                color: AppColor.textSecondary,
                fontSize: 11,
              ),
            ),
          ] else ...[
            const SizedBox(width: 8),
            Text(
              '${members.length} member${members.length == 1 ? '' : 's'}',
              style: GoogleFonts.urbanist(
                color: AppColor.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Balance Section ───────────────────────────────────────────────────────────

class _BalanceSection extends StatelessWidget {
  final SplitsController ctrl;
  final String myUid;
  const _BalanceSection({required this.ctrl, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');

    return Obx(() {
      final totalOwed = ctrl.myTotalOwed();
      final totalToMe = ctrl.totalOwedToMe();
      final allSettled = totalOwed == 0 && totalToMe == 0 && ctrl.myBalances.isEmpty;

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary banner ───────────────────────────────────────────────
            if (allSettled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColor.income.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const PhosphorIcon(
                      PhosphorIconsLight.checkCircle,
                      color: AppColor.income,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'All settled up!',
                      style: GoogleFonts.urbanist(
                        color: AppColor.income,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  if (totalOwed > 0)
                    Expanded(
                      child: _BalanceBanner(
                        label: 'You owe',
                        amount: '₹${fmt.format(totalOwed)}',
                        color: AppColor.expense,
                        bgColor: AppColor.expenseSoft,
                      ),
                    ),
                  if (totalOwed > 0 && totalToMe > 0)
                    const SizedBox(width: 10),
                  if (totalToMe > 0)
                    Expanded(
                      child: _BalanceBanner(
                        label: 'You\'re owed',
                        amount: '₹${fmt.format(totalToMe)}',
                        color: AppColor.income,
                        bgColor: AppColor.incomeSoft.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),

            // ── Per-person rows ──────────────────────────────────────────────
            if (ctrl.myBalances.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...ctrl.myBalances.entries.map((e) {
                final isOwed = e.value > 0;
                final color = isOwed ? AppColor.income : AppColor.expense;
                final personName = ctrl.nameOf(e.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _InitialAvatar(name: personName, color: color, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              personName,
                              style: GoogleFonts.urbanist(
                                color: AppColor.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              isOwed ? 'owes you' : 'you owe',
                              style: GoogleFonts.urbanist(
                                color: AppColor.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${fmt.format(e.value.abs())}',
                        style: GoogleFonts.urbanist(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // ── Group settlements ────────────────────────────────────────────
            if (ctrl.simplifiedDebts.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Suggested settlements',
                style: GoogleFonts.urbanist(
                  color: AppColor.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...ctrl.simplifiedDebts.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _InitialAvatar(
                        name: d.fromName,
                        color: AppColor.expense,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      const PhosphorIcon(
                        PhosphorIconsLight.arrowRight,
                        size: 14,
                        color: AppColor.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      _InitialAvatar(
                        name: d.toName,
                        color: AppColor.income,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: AppColor.textSecondary,
                            ),
                            children: [
                              TextSpan(
                                text: d.fromName,
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                              const TextSpan(text: ' pays '),
                              TextSpan(
                                text: d.toName,
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        '₹${fmt.format(d.amount)}',
                        style: GoogleFonts.urbanist(
                          color: AppColor.expense,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Balance Banner ─────────────────────────────────────────────────────────────

class _BalanceBanner extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final Color bgColor;

  const _BalanceBanner({
    required this.label,
    required this.amount,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.urbanist(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            amount,
            style: GoogleFonts.urbanist(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Initial Avatar ─────────────────────────────────────────────────────────────

class _InitialAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  const _InitialAvatar({required this.name, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.urbanist(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}

// ── Month Header ──────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final String month;
  const _MonthHeader({required this.month});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Text(
        month,
        style: GoogleFonts.urbanist(
          color: AppColor.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Split Tile ────────────────────────────────────────────────────────────────

class _SplitTile extends StatefulWidget {
  final int index;
  final SplitsController ctrl;
  final String myUid;

  const _SplitTile({
    super.key,
    required this.index,
    required this.ctrl,
    required this.myUid,
  });

  @override
  State<_SplitTile> createState() => _SplitTileState();
}

class _SplitTileState extends State<_SplitTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final split = widget.ctrl.splits[widget.index];
    final myUid = widget.myUid;
    final fmt = NumberFormat('#,##0.00');

    final catColor = AppColor.categoryColor(split.category);
    final paidByMe = split.paidBy == myUid;
    final myShare = split.shares.where((s) => s.userId == myUid).firstOrNull;
    final isFullySettled =
        split.shares.every((s) => s.isSettled || s.userId == split.paidBy);
    final pendingFromOthers = paidByMe
        ? split.shares
            .where((s) => s.userId != split.paidBy && !s.isSettled)
            .fold(0.0, (sum, s) => sum + s.amountOwed)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.border),
        ),
        child: Column(
          children: [
            // ── Tile header ────────────────────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Category icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          _catIcon(split.category),
                          color: catColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            split.title,
                            style: GoogleFonts.urbanist(
                              color: AppColor.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            paidByMe
                                ? 'You paid'
                                : 'Paid by ${widget.ctrl.nameOf(split.paidBy)}',
                            style: GoogleFonts.urbanist(
                              color: AppColor.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount + your share context
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${fmt.format(split.totalAmount)}',
                          style: GoogleFonts.urbanist(
                            color: AppColor.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (isFullySettled)
                          Text(
                            'settled',
                            style: GoogleFonts.urbanist(
                              color: AppColor.income,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (paidByMe && pendingFromOthers > 0)
                          Text(
                            'you lent ₹${fmt.format(pendingFromOthers)}',
                            style: GoogleFonts.urbanist(
                              color: AppColor.income,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (myShare != null &&
                            !myShare.isSettled &&
                            !paidByMe)
                          Text(
                            'you owe ₹${fmt.format(myShare.amountOwed)}',
                            style: GoogleFonts.urbanist(
                              color: AppColor.expense,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            DateFormat('d MMM').format(split.date),
                            style: GoogleFonts.urbanist(
                              color: AppColor.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    PhosphorIcon(
                      _expanded
                          ? PhosphorIconsLight.caretUp
                          : PhosphorIconsLight.caretDown,
                      size: 14,
                      color: AppColor.textTertiary,
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded detail ────────────────────────────────────────────
            if (_expanded) ...[
              const Divider(height: 1, color: AppColor.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (split.notes != null &&
                        split.notes!.isNotEmpty) ...[
                      Text(
                        split.notes!,
                        style: GoogleFonts.urbanist(
                          color: AppColor.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ...List.generate(
                      split.shares.length,
                      (i) => _ShareRow(
                        key: ValueKey(split.shares[i].id),
                        share: split.shares[i],
                        split: split,
                        ctrl: widget.ctrl,
                        myUid: myUid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  PhosphorIconData _catIcon(String cat) {
    final k = cat.toLowerCase();
    if (k.contains('food') || k.contains('drink') || k.contains('restaurant')) {
      return PhosphorIconsLight.forkKnife;
    }
    if (k.contains('grocer')) { return PhosphorIconsLight.shoppingCart; }
    if (k.contains('transport') || k.contains('bus')) { return PhosphorIconsLight.bus; }
    if (k.contains('car') || k.contains('fuel')) { return PhosphorIconsLight.car; }
    if (k.contains('shop')) { return PhosphorIconsLight.bag; }
    if (k.contains('bill')) { return PhosphorIconsLight.lightning; }
    if (k.contains('health') || k.contains('medical')) { return PhosphorIconsLight.pill; }
    if (k.contains('entertain') || k.contains('film')) { return PhosphorIconsLight.filmSlate; }
    if (k.contains('travel') || k.contains('trip')) { return PhosphorIconsLight.airplane; }
    if (k.contains('invest')) { return PhosphorIconsLight.trendUp; }
    if (k.contains('edu')) { return PhosphorIconsLight.graduationCap; }
    if (k.contains('subscri')) { return PhosphorIconsLight.receipt; }
    if (k.contains('gift')) { return PhosphorIconsLight.gift; }
    return PhosphorIconsLight.tag;
  }
}

// ── Share Row ─────────────────────────────────────────────────────────────────

class _ShareRow extends StatefulWidget {
  final SplitShare share;
  final SplitModel split;
  final SplitsController ctrl;
  final String myUid;

  const _ShareRow({
    super.key,
    required this.share,
    required this.split,
    required this.ctrl,
    required this.myUid,
  });

  @override
  State<_ShareRow> createState() => _ShareRowState();
}

class _ShareRowState extends State<_ShareRow> {
  bool _settling = false;

  @override
  Widget build(BuildContext context) {
    final share = widget.share;
    final ctrl = widget.ctrl;
    final fmt = NumberFormat('#,##0.00');
    final name = ctrl.nameOf(share.userId);
    final isMe = share.userId == widget.myUid;
    final isPayer = share.userId == widget.split.paidBy;
    final canSettle = !share.isSettled && !isPayer && isMe;

    final avatarColor = share.isSettled
        ? AppColor.income
        : (isPayer ? AppColor.primary : AppColor.expense);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _InitialAvatar(name: name, color: avatarColor, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'You' : name,
                  style: GoogleFonts.urbanist(
                    color: AppColor.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isPayer
                      ? 'Paid'
                      : share.isSettled
                          ? 'Settled'
                          : 'Due',
                  style: GoogleFonts.urbanist(
                    color: avatarColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${fmt.format(share.amountOwed)}',
            style: GoogleFonts.urbanist(
              color: share.isSettled
                  ? AppColor.income
                  : (isPayer ? AppColor.primary : AppColor.expense),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (share.isSettled) ...[
            const SizedBox(width: 8),
            const PhosphorIcon(
              PhosphorIconsLight.checkCircle,
              color: AppColor.income,
              size: 16,
            ),
          ] else if (canSettle) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _settling ? null : _settle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: _settling
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColor.primary,
                        ),
                      )
                    : Text(
                        'Settle',
                        style: GoogleFonts.urbanist(
                          color: AppColor.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _settle() async {
    setState(() => _settling = true);
    await widget.ctrl.settleShare(
      share: widget.share,
      split: widget.split,
    );
    if (mounted) setState(() => _settling = false);
  }
}

// ── Empty Splits ──────────────────────────────────────────────────────────────

class _EmptySplits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColor.primaryExtraSoft,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: PhosphorIcon(
                PhosphorIconsLight.receipt,
                size: 26,
                color: AppColor.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No expenses yet',
            style: GoogleFonts.urbanist(
              color: AppColor.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add expense" to log your first split',
            style: GoogleFonts.urbanist(
              color: AppColor.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
