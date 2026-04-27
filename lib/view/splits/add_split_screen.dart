import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/splits_controller/splits_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/group_model.dart';
import 'package:spendify/view/splits/bill_scanner_screen.dart';

class AddSplitScreen extends StatefulWidget {
  final SplitsController ctrl;
  const AddSplitScreen({super.key, required this.ctrl});

  @override
  State<AddSplitScreen> createState() => _AddSplitScreenState();
}

class _AddSplitScreenState extends State<AddSplitScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String _category = 'Others';
  String? _paidByUserId;
  bool _equalSplit = true;

  // Custom split amounts per userId
  final Map<String, TextEditingController> _customAmtCtrls = {};
  late final Worker _membersWorker;

  static const _categories = [
    'Food & Drinks', 'Groceries', 'Transport', 'Car', 'Shopping',
    'Bills & Fees', 'Health', 'Entertainment', 'Travel', 'Investments',
    'Education', 'Subscriptions', 'Gifts', 'Others',
  ];

  @override
  void initState() {
    super.initState();
    _syncMembers(widget.ctrl.members);
    _membersWorker = ever(widget.ctrl.members, _syncMembers);
  }

  void _syncMembers(List<GroupMember> members) {
    if (members.isEmpty) return;
    final myUid = supabaseC.auth.currentUser?.id;
    // Auto-select payer the first time members load
    if (_paidByUserId == null) {
      final payer = members.any((m) => m.userId == myUid)
          ? myUid
          : members.first.userId;
      if (mounted) {
        setState(() => _paidByUserId = payer);
      } else {
        _paidByUserId = payer;
      }
    }
    // Create amount controllers for any new members
    for (final m in members) {
      _customAmtCtrls.putIfAbsent(m.userId, () => TextEditingController());
    }
  }

  @override
  void dispose() {
    _membersWorker.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _customAmtCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIconsLight.caretLeft, color: textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Add expense',
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Scan bill QR',
            icon: PhosphorIcon(PhosphorIconsLight.qrCode, color: textPrimary, size: 20),
            onPressed: () async {
              final result = await Get.to<BillScanResult>(
                () => const BillScannerScreen(),
                transition: Transition.cupertino,
              );
              if (result == null) return;
              if (result.title != null && result.title!.isNotEmpty) {
                _titleCtrl.text = result.title!;
              }
              if (result.amount != null && result.amount!.isNotEmpty) {
                _amountCtrl.text = result.amount!;
                setState(() {});
              }
              if (result.notes != null && result.notes!.isNotEmpty) {
                _notesCtrl.text = result.notes!;
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ───────────────────────────────────────────────────────
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Dinner, Hotel, Taxi...',
              ),
            ),
            const SizedBox(height: 16),

            // ── Amount ──────────────────────────────────────────────────────
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Total amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 16),

            // ── Date ────────────────────────────────────────────────────────
            _SectionLabel(label: 'Date', textMuted: textMuted),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    PhosphorIcon(PhosphorIconsLight.calendarBlank, size: 16, color: textMuted),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('d MMMM yyyy').format(_date),
                      style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    PhosphorIcon(PhosphorIconsLight.caretDown, size: 14, color: textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Category ────────────────────────────────────────────────────
            _SectionLabel(label: 'Category', textMuted: textMuted),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isSelected = cat == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColor.primary : cardBg,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected ? AppColor.primary : border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textMuted,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Paid by ─────────────────────────────────────────────────────
            _SectionLabel(label: 'Paid by', textMuted: textMuted),
            const SizedBox(height: 10),
            Obx(() {
              final members = widget.ctrl.members;
              if (members.isEmpty) {
                return Text('Loading members…', style: TextStyle(color: textMuted, fontSize: 13));
              }
              final myUid = supabaseC.auth.currentUser?.id;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: members.map((m) {
                  final isSelected = m.userId == _paidByUserId;
                  final label = m.userId == myUid ? 'You' : m.displayName;
                  return GestureDetector(
                    onTap: () => setState(() => _paidByUserId = m.userId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColor.primary : cardBg,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: isSelected ? AppColor.primary : border),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textMuted,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 20),

            // ── Split method ────────────────────────────────────────────────
            _SectionLabel(label: 'Split method', textMuted: textMuted),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  _SplitMethodTab(
                    label: 'Equal',
                    icon: PhosphorIconsLight.equals,
                    isActive: _equalSplit,
                    isDark: isDark,
                    onTap: () => setState(() => _equalSplit = true),
                  ),
                  _SplitMethodTab(
                    label: 'Custom',
                    icon: PhosphorIconsLight.pencilSimple,
                    isActive: !_equalSplit,
                    isDark: isDark,
                    onTap: () => setState(() => _equalSplit = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Per-member shares ────────────────────────────────────────────
            _SectionLabel(label: 'Shares', textMuted: textMuted),
            const SizedBox(height: 10),
            Obx(() {
              final members = widget.ctrl.members;
              if (members.isEmpty) {
                return Text('Loading members…', style: TextStyle(color: textMuted, fontSize: 13));
              }
              return Column(
                children: _buildShareRows(members, textPrimary, textMuted, cardBg, border),
              );
            }),

            // ── Notes ───────────────────────────────────────────────────────
            const SizedBox(height: 20),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any extra details...',
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit ──────────────────────────────────────────────────────
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.ctrl.isSubmitting.value ? null : _submit,
                child: widget.ctrl.isSubmitting.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add expense'),
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShareRows(
    List<GroupMember> members,
    Color textPrimary,
    Color textMuted,
    Color cardBg,
    Color border,
  ) {
    final total = double.tryParse(_amountCtrl.text) ?? 0;
    final equalShare = members.isNotEmpty ? total / members.length : 0.0;
    final myUid = supabaseC.auth.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return members.map((m) {
      final isMe = m.userId == myUid;
      final label = isMe ? 'You' : m.displayName;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label.isNotEmpty ? label[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_equalSplit)
              Text(
                total > 0
                    ? '₹${NumberFormat('#,##0.00').format(equalShare)}'
                    : '—',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _customAmtCtrls[m.userId],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(color: textMuted, fontSize: 13),
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? AppColor.darkBorderFocus : AppColor.lightBorderFocus,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColor.primary,
            brightness: Theme.of(ctx).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final total = double.tryParse(_amountCtrl.text) ?? 0;

    if (title.isEmpty) {
      _showError('Please enter a description');
      return;
    }
    if (total <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    if (_paidByUserId == null) {
      _showError('Please select who paid');
      return;
    }

    final members = List<GroupMember>.from(widget.ctrl.members);
    if (members.isEmpty) {
      _showError('Members are still loading, please wait');
      return;
    }

    Map<String, double> shares;

    if (_equalSplit) {
      final each = total / members.length;
      shares = {for (final m in members) m.userId: each};
    } else {
      shares = {};
      double customTotal = 0;
      for (final m in members) {
        final v = double.tryParse(_customAmtCtrls[m.userId]?.text ?? '') ?? 0;
        shares[m.userId] = v;
        customTotal += v;
      }
      // Validate custom amounts sum
      if ((customTotal - total).abs() > 0.02) {
        _showError(
          'Custom amounts (₹${NumberFormat('#,##0.00').format(customTotal)}) '
          'must add up to ₹${NumberFormat('#,##0.00').format(total)}',
        );
        return;
      }
    }

    final ok = await widget.ctrl.createSplit(
      title: title,
      totalAmount: total,
      paidByUserId: _paidByUserId!,
      category: _category,
      date: _date,
      shares: shares,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (ok && mounted) Get.back();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColor.expense,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textMuted;
  const _SectionLabel({required this.label, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500));
  }
}

class _SplitMethodTab extends StatelessWidget {
  final String label;
  final PhosphorIconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _SplitMethodTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? AppColor.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, size: 14,
                  color: isActive ? Colors.white : (isDark ? AppColor.textSecondary : const Color(0xFF71717A))),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : (isDark ? AppColor.textSecondary : const Color(0xFF71717A)),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
