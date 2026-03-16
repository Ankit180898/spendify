import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/groups_controller/groups_controller.dart';
import 'package:spendify/controller/splits_controller/splits_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/group_model.dart';
import 'package:spendify/model/split_model.dart';
import 'package:spendify/view/splits/add_split_screen.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

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
  }

  @override
  void dispose() {
    Get.delete<SplitsController>(tag: widget.group.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFEEEEEE);
    final myUid = supabaseC.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: bg,
      // ✅ Obx removed from here — only wraps specific reactive sections below
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: bg,
            elevation: 0,
            pinned: true,
            expandedHeight: 140,
            leading: IconButton(
              icon: PhosphorIcon(PhosphorIconsLight.caretLeft,
                  color: textPrimary),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: PhosphorIcon(PhosphorIconsLight.doorOpen,
                    color: textMuted, size: 20),
                onPressed: () => _confirmLeave(context, isDark),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(widget.group.emoji,
                              style: const TextStyle(fontSize: 30)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.group.name,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                // ✅ Only member count is reactive
                                Obx(() => Text(
                                      '${_ctrl.members.length} members',
                                      style: TextStyle(
                                          color: textMuted, fontSize: 13),
                                    )),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: widget.group.inviteCode));
                              CustomToast.successToast(
                                  'Copied!', 'Invite code copied to clipboard');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColor.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color:
                                      AppColor.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const PhosphorIcon(
                                    PhosphorIconsLight.copySimple,
                                    size: 12,
                                    color: AppColor.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.group.inviteCode,
                                    style: const TextStyle(
                                      color: AppColor.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: border),
            ),
          ),

          // ✅ Only loading state is reactive
          Obx(() {
            if (_ctrl.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }),

          // ✅ Only balances section is reactive
          Obx(() {
            if (_ctrl.isLoading.value)
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            if (_ctrl.myBalances.isEmpty && _ctrl.simplifiedDebts.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverToBoxAdapter(
              child: _BalancesSection(
                ctrl: _ctrl,
                myUid: myUid,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            );
          }),

          // Expenses header — static, no Obx needed
          SliverToBoxAdapter(
            child: Obx(() => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Expenses',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_ctrl.splits.length} total',
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )),
          ),

          // ✅ Only splits list is reactive
          Obx(() {
            if (_ctrl.isLoading.value)
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            if (_ctrl.splits.isEmpty) {
              return SliverToBoxAdapter(
                child: _EmptySplits(isDark: isDark, textMuted: textMuted),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _SplitTile(
                  index: i, // ✅ pass index
                  ctrl: _ctrl,
                  myUid: myUid,
                  isDark: isDark,
                ),
                childCount: _ctrl.splits.length,
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
        label: const Text('Add expense',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _confirmLeave(BuildContext context, bool isDark) {
    final bg = isDark ? AppColor.darkSurface : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColor.darkBorder : const Color(0xFFE0E0E0),
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
                child: PhosphorIcon(PhosphorIconsLight.doorOpen,
                    color: AppColor.expense, size: 26),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Leave group?',
              style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You will lose access to all splits in "${widget.group.name}". Unsettled balances will remain.',
              style: TextStyle(color: textMuted, fontSize: 14, height: 1.5),
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
                      borderRadius: BorderRadius.circular(100)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Leave group',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel',
                    style: TextStyle(
                        color: textMuted, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Balances Section ──────────────────────────────────────────────────────────

class _BalancesSection extends StatelessWidget {
  final SplitsController ctrl;
  final String myUid;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;

  const _BalancesSection({
    required this.ctrl,
    required this.myUid,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF9F9F9);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFEEEEEE);
    final fmt = NumberFormat('#,##0.00');

    // ✅ Obx so balances section rebuilds when myBalances/simplifiedDebts change
    return Obx(() {
      final totalOwed = ctrl.myTotalOwed();
      final totalToMe = ctrl.totalOwedToMe();

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your balance',
              style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (totalOwed > 0)
                  Expanded(
                    child: _BalancePill(
                      label: 'You owe',
                      amount: totalOwed,
                      color: AppColor.expense,
                      isDark: isDark,
                    ),
                  ),
                if (totalOwed > 0 && totalToMe > 0) const SizedBox(width: 10),
                if (totalToMe > 0)
                  Expanded(
                    child: _BalancePill(
                      label: 'Owed to you',
                      amount: totalToMe,
                      color: AppColor.income,
                      isDark: isDark,
                    ),
                  ),
                if (totalOwed == 0 && totalToMe == 0)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColor.income.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          PhosphorIcon(PhosphorIconsLight.checkCircle,
                              color: AppColor.income, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'All settled up!',
                            style: TextStyle(
                              color: AppColor.income,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (ctrl.myBalances.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...ctrl.myBalances.entries.map((e) {
                final isOwed = e.value > 0;
                final color = isOwed ? AppColor.income : AppColor.expense;
                final label = isOwed
                    ? '${ctrl.nameOf(e.key)} owes you'
                    : 'You owe ${ctrl.nameOf(e.key)}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            ctrl.nameOf(e.key).isNotEmpty
                                ? ctrl.nameOf(e.key)[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(label,
                            style: TextStyle(color: textMuted, fontSize: 13)),
                      ),
                      Text(
                        '₹${fmt.format(e.value.abs())}',
                        style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (ctrl.simplifiedDebts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Group settlements',
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...ctrl.simplifiedDebts.map((d) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        _MiniAvatar(name: d.fromName, color: AppColor.expense),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: d.fromName,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: ' → ',
                                  style:
                                      TextStyle(color: textMuted, fontSize: 13),
                                ),
                                TextSpan(
                                  text: d.toName,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          '₹${fmt.format(d.amount)}',
                          style: const TextStyle(
                            color: AppColor.expense,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      );
    }); // ✅ closes Obx
  }
}

class _BalancePill extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isDark;

  const _BalancePill({
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
                color: color, fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String name;
  final Color color;
  const _MiniAvatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

// ── Split Tile ────────────────────────────────────────────────────────────────

class _SplitTile extends StatefulWidget {
  final int index; // ✅ index instead of split
  final SplitsController ctrl;
  final String myUid;
  final bool isDark;

  const _SplitTile({
    required this.index,
    required this.ctrl,
    required this.myUid,
    required this.isDark,
  });

  @override
  State<_SplitTile> createState() => _SplitTileState();
}

class _SplitTileState extends State<_SplitTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final split = widget.ctrl
        .splits[widget.index]; // ✅ read split fresh using index from RxList
    final isDark = widget.isDark;
    final myUid = widget.myUid;
    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF9F9F9);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFEEEEEE);
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: PhosphorIcon(_catIcon(split.category),
                            color: catColor, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            split.title,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            paidByMe
                                ? 'You paid'
                                : 'Paid by ${widget.ctrl.nameOf(split.paidBy)}',
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${fmt.format(split.totalAmount)}',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (isFullySettled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColor.income.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Settled',
                              style: TextStyle(
                                color: AppColor.income,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else if (paidByMe && pendingFromOthers > 0)
                          Text(
                            '₹${fmt.format(pendingFromOthers)} pending',
                            style: const TextStyle(
                              color: AppColor.income,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else if (myShare != null &&
                            !myShare.isSettled &&
                            !paidByMe)
                          Text(
                            'You owe ₹${fmt.format(myShare.amountOwed)}',
                            style: const TextStyle(
                              color: AppColor.expense,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            DateFormat('d MMM').format(split.date),
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    PhosphorIcon(
                      _expanded
                          ? PhosphorIconsLight.caretUp
                          : PhosphorIconsLight.caretDown,
                      size: 14,
                      color: textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              Divider(height: 1, color: border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (split.notes != null && split.notes!.isNotEmpty) ...[
                      Text(
                        split.notes!,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    // ✅ Pass index so _ShareRow reads live data from RxList
                    Column(
                        children: List.generate(
                            split.shares.length,
                            (i) => _ShareRow(
                                  share: split.shares[i],
                                  split: split,
                                  ctrl: widget.ctrl,
                                  myUid: myUid,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textMuted: textMuted,
                                )),
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
    if (k.contains('food') || k.contains('drink') || k.contains('restaurant'))
      return PhosphorIconsLight.forkKnife;
    if (k.contains('grocer')) return PhosphorIconsLight.shoppingCart;
    if (k.contains('transport') || k.contains('bus'))
      return PhosphorIconsLight.bus;
    if (k.contains('car') || k.contains('fuel')) return PhosphorIconsLight.car;
    if (k.contains('shop')) return PhosphorIconsLight.bag;
    if (k.contains('bill')) return PhosphorIconsLight.lightning;
    if (k.contains('health') || k.contains('medical'))
      return PhosphorIconsLight.pill;
    if (k.contains('entertain') || k.contains('film'))
      return PhosphorIconsLight.filmSlate;
    if (k.contains('travel') || k.contains('trip'))
      return PhosphorIconsLight.airplane;
    if (k.contains('invest')) return PhosphorIconsLight.trendUp;
    if (k.contains('edu')) return PhosphorIconsLight.graduationCap;
    if (k.contains('subscri')) return PhosphorIconsLight.receipt;
    if (k.contains('gift')) return PhosphorIconsLight.gift;
    return PhosphorIconsLight.tag;
  }
}

// ── Share Row ─────────────────────────────────────────────────────────────────

class _ShareRow extends StatefulWidget {
  final SplitShare share;
  final SplitModel split;
  final SplitsController ctrl;
  final String myUid;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;

  const _ShareRow({
    required this.share,
    required this.split,
    required this.ctrl,
    required this.myUid,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _MiniAvatar(
            name: name,
            color: share.isSettled
                ? AppColor.income
                : (isPayer ? AppColor.primary : AppColor.expense),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'You' : name,
                  style: TextStyle(
                    color: widget.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isPayer)
                  const Text('Paid',
                      style: TextStyle(color: AppColor.income, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '₹${fmt.format(share.amountOwed)}',
            style: TextStyle(
              color: share.isSettled
                  ? AppColor.income
                  : (isPayer ? AppColor.primary : AppColor.expense),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (share.isSettled) ...[
            const SizedBox(width: 8),
            const PhosphorIcon(PhosphorIconsLight.checkCircle,
                color: AppColor.income, size: 16),
          ] else if (canSettle) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _settling ? null : _settle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: _settling
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColor.primary),
                      )
                    : const Text(
                        'Settle',
                        style: TextStyle(
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
    await widget.ctrl.settleShare(share: widget.share, split: widget.split);
    if (mounted) setState(() => _settling = false);
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptySplits extends StatelessWidget {
  final bool isDark;
  final Color textMuted;
  const _EmptySplits({required this.isDark, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: PhosphorIcon(PhosphorIconsLight.receipt,
                  size: 28, color: AppColor.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: TextStyle(
              color: isDark ? AppColor.textPrimary : const Color(0xFF09090B),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "+ Add expense" to log the first split expense',
            style: TextStyle(color: textMuted, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
