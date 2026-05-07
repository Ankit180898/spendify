import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Scaffold(
      backgroundColor: AppColor.bg,
      appBar: AppBar(
        backgroundColor: AppColor.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const PhosphorIcon(
            PhosphorIconsLight.caretLeft,
            color: AppColor.textPrimary,
            size: 20,
          ),
          onPressed: Get.back,
        ),
        title: Text(
          'Add expense',
          style: GoogleFonts.urbanist(
            color: AppColor.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColor.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scan bill ───────────────────────────────────────────────────
            GestureDetector(
              onTap: _scanBill,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColor.primary.withValues(alpha: 0.14)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: PhosphorIcon(
                          PhosphorIconsLight.qrCode,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan bill QR code',
                            style: GoogleFonts.urbanist(
                              color: AppColor.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Auto-fill amount from UPI or merchant QR',
                            style: GoogleFonts.urbanist(
                              color: AppColor.textSecondary,
                              fontSize: 12,
                            ),
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
            ),
            const SizedBox(height: 20),

            // ── Description ─────────────────────────────────────────────────
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Dinner, Hotel, Taxi…',
              ),
            ),
            const SizedBox(height: 14),

            // ── Amount ──────────────────────────────────────────────────────
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Total amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 20),

            // ── Date ────────────────────────────────────────────────────────
            _Label('Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColor.border),
                ),
                child: Row(
                  children: [
                    const PhosphorIcon(
                      PhosphorIconsLight.calendarBlank,
                      size: 16,
                      color: AppColor.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('d MMMM yyyy').format(_date),
                      style: GoogleFonts.urbanist(
                        color: AppColor.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const PhosphorIcon(
                      PhosphorIconsLight.caretDown,
                      size: 14,
                      color: AppColor.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Category ────────────────────────────────────────────────────
            _Label('Category'),
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColor.primary
                            : AppColor.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? AppColor.primary
                              : AppColor.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: GoogleFonts.urbanist(
                          color: isSelected
                              ? Colors.white
                              : AppColor.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Paid by ─────────────────────────────────────────────────────
            _Label('Paid by'),
            const SizedBox(height: 10),
            Obx(() {
              final members = widget.ctrl.members;
              if (members.isEmpty) {
                return Text(
                  'Loading members…',
                  style: GoogleFonts.urbanist(
                    color: AppColor.textSecondary,
                    fontSize: 13,
                  ),
                );
              }
              final myUid = supabaseC.auth.currentUser?.id;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: members.map((m) {
                  final isSelected = m.userId == _paidByUserId;
                  final label =
                      m.userId == myUid ? 'You' : m.displayName;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _paidByUserId = m.userId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColor.primary
                            : AppColor.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? AppColor.primary
                              : AppColor.border,
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.urbanist(
                          color: isSelected
                              ? Colors.white
                              : AppColor.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 20),

            // ── Split method ────────────────────────────────────────────────
            _Label('Split method'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColor.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _MethodTab(
                    label: 'Equal split',
                    icon: PhosphorIconsLight.equals,
                    isActive: _equalSplit,
                    onTap: () => setState(() => _equalSplit = true),
                  ),
                  _MethodTab(
                    label: 'Custom amounts',
                    icon: PhosphorIconsLight.pencilSimple,
                    isActive: !_equalSplit,
                    onTap: () => setState(() => _equalSplit = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Per-member shares ────────────────────────────────────────────
            _Label('Who owes what'),
            const SizedBox(height: 10),
            Obx(() {
              final members = widget.ctrl.members;
              if (members.isEmpty) {
                return Text(
                  'Loading members…',
                  style: GoogleFonts.urbanist(
                    color: AppColor.textSecondary,
                    fontSize: 13,
                  ),
                );
              }
              return Column(
                children: _buildShareRows(members),
              );
            }),

            // ── Notes ───────────────────────────────────────────────────────
            const SizedBox(height: 20),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any extra details…',
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit ──────────────────────────────────────────────────────
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        widget.ctrl.isSubmitting.value ? null : _submit,
                    child: widget.ctrl.isSubmitting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Add expense'),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShareRows(List<GroupMember> members) {
    final total = double.tryParse(_amountCtrl.text) ?? 0;
    final equalShare = members.isNotEmpty ? total / members.length : 0.0;
    final myUid = supabaseC.auth.currentUser?.id;

    return members.map((m) {
      final isMe = m.userId == myUid;
      final label = isMe ? 'You' : m.displayName;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColor.primaryExtraSoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label.isNotEmpty ? label[0].toUpperCase() : '?',
                  style: GoogleFonts.urbanist(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.urbanist(
                  color: AppColor.textPrimary,
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
                style: GoogleFonts.urbanist(
                  color: AppColor.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _customAmtCtrls[m.userId],
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  textAlign: TextAlign.right,
                  style: GoogleFonts.urbanist(
                    color: AppColor.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.urbanist(
                      color: AppColor.textSecondary,
                      fontSize: 13,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColor.borderFocus),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 4),
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

  Future<void> _scanBill() async {
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
        final v =
            double.tryParse(_customAmtCtrls[m.userId]?.text ?? '') ?? 0;
        shares[m.userId] = v;
        customTotal += v;
      }
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

// ── Section Label ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.urbanist(
        color: AppColor.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Split Method Tab ──────────────────────────────────────────────────────────

class _MethodTab extends StatelessWidget {
  final String label;
  final PhosphorIconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _MethodTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColor.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                icon,
                size: 14,
                color: isActive
                    ? AppColor.textPrimary
                    : AppColor.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.urbanist(
                  color: isActive
                      ? AppColor.textPrimary
                      : AppColor.textSecondary,
                  fontSize: 13,
                  fontWeight: isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
