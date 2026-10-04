import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/services/progress_service.dart';
import 'package:spendify/services/voice_parser_service.dart';
import 'package:spendify/utils/utils.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  final Map<String, dynamic>? transaction; // non-null = edit mode
  const AddTransactionScreen({
    super.key,
    this.initialType = 'expense',
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final controller = Get.find<TransactionController>();
  late final _isExpense = (widget.initialType == 'expense').obs;
  final _amount = ''.obs;
  final _noteFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _scrollCtrl = ScrollController();

  // Voice input
  final _speech = SpeechToText();
  bool _speechAvailable = false;
  final _voiceText = ''.obs;
  final _isListening = false.obs;

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize();
    } catch (_) {
      _speechAvailable = false;
    }
  }

  Future<void> _startVoiceInput() async {
    if (!_speechAvailable) {
      try {
        _speechAvailable = await _speech.initialize();
      } catch (_) {
        _speechAvailable = false;
      }
    }

    _voiceText.value = '';
    _isListening.value = false;

    const isDark = false; // app is light-only
    const sheetBg = AppColor.surface;

    await Get.bottomSheet(
      _speechAvailable
          ? _VoiceSheet(
              speech: _speech,
              voiceText: _voiceText,
              isListening: _isListening,
              isDark: isDark)
          : _TextInputSheet(voiceText: _voiceText, isDark: isDark),
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
    );

    _isListening.value = false;
    if (_speech.isListening) {
      await _speech.stop();
    }

    final text = _voiceText.value.trim();
    if (text.isEmpty) {
      return;
    }

    final result = VoiceParserService.parse(text);

    if (result.amount != null) {
      final amtStr = result.amount! % 1 == 0
          ? result.amount!.toInt().toString()
          : result.amount!.toString();
      _amount.value = amtStr;
      controller.amountController.text = amtStr;
    }
    if (result.category != null) {
      controller.selectedCategory.value = result.category!;
      // Warn if confidence is below 60% so the user knows to double-check
      if ((result.categoryConfidence ?? 1.0) < 0.6) {
        Future.microtask(() => Get.snackbar(
              'Check category',
              'Voice picked "${result.category}" — tap another if wrong',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 3),
              backgroundColor: AppColor.surface,
              colorText: AppColor.textPrimary,
              margin: const EdgeInsets.all(12),
              borderRadius: 12,
              icon: const PhosphorIcon(
                PhosphorIconsLight.warningCircle,
                color: AppColor.warning,
                size: 20,
              ),
            ));
      }
    }
    if (result.description != null && result.description!.isNotEmpty) {
      controller.titleController.text = result.description!;
    }
    _setType(result.type == 'expense');
  }

  bool get _isEditMode => widget.transaction != null;
  String get _transactionId => widget.transaction!['id'].toString();

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    if (tx != null) {
      // Edit mode — pre-fill from existing transaction
      final type = tx['type'] as String? ?? 'expense';
      controller.selectedType.value = type;
      _isExpense.value = type == 'expense';
      final amt = tx['amount']?.toString() ?? '';
      _amount.value = amt;
      controller.amountController.text = amt;
      controller.selectedCategory.value = tx['category'] as String? ?? '';
      controller.selectedDate.value =
          tx['date'] as String? ?? DateTime.now().toIso8601String();
      final note = tx['description'] as String? ?? '';
      controller.titleController.text = note;
    } else {
      controller.resetForm();
      controller.selectedType.value = widget.initialType;
    }
    _noteFocus.addListener(() => setState(() {}));
    _initSpeech();
  }

  @override
  void dispose() {
    _amountFocus.dispose();
    _noteFocus.dispose();
    _scrollCtrl.dispose();
    if (_speech.isListening) _speech.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _tapKey(String key) {
    HapticFeedback.lightImpact();
    final tc = controller.amountController;
    final text = tc.text;
    final sel = tc.selection;

    final hasValidSel = sel.isValid && sel.baseOffset >= 0;
    final start = hasValidSel ? sel.start : text.length;
    final end = hasValidSel ? sel.end : text.length;

    if (key == '⌫') {
      if (start == end) {
        if (start > 0) {
          final newText = text.substring(0, start - 1) + text.substring(start);
          tc.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: start - 1),
          );
        }
      } else {
        final newText = text.substring(0, start) + text.substring(end);
        tc.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start),
        );
      }
    } else if (key == '.') {
      if (!text.contains('.')) {
        final String newText;
        final int newOffset;
        if (text.isEmpty) {
          newText = '0.';
          newOffset = 2;
        } else {
          newText = text.substring(0, start) + '.' + text.substring(end);
          newOffset = start + 1;
        }
        tc.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
        );
      }
    } else {
      final prefix = text.substring(0, start);
      final suffix = text.substring(end);
      final combined = prefix + suffix;
      if (text == '0' && start == 1 && end == 1) {
        tc.value = TextEditingValue(
          text: key,
          selection: TextSelection.collapsed(offset: 1),
        );
      } else {
        final parts = combined.split('.');
        if (parts[0].length < 10) {
          tc.value = TextEditingValue(
            text: prefix + key + suffix,
            selection: TextSelection.collapsed(offset: start + 1),
          );
        }
      }
    }
    _amount.value = tc.text;
  }

  void _setType(bool isExpense) {
    HapticFeedback.selectionClick();
    _isExpense.value = isExpense;
    controller.selectedType.value = isExpense ? 'expense' : 'income';
  }

  void _submit() {
    HapticFeedback.mediumImpact();
    if (_isEditMode) {
      controller.updateTransaction(_transactionId);
      return;
    }
    // Auto-fill note with category if empty
    if (controller.titleController.text.trim().isEmpty) {
      final cat = controller.selectedCategory.value;
      controller.titleController.text =
          cat.isNotEmpty ? cat : (_isExpense.value ? 'Expense' : 'Income');
    }
    controller.addResource();
  }

  // ── Categories ────────────────────────────────────────────────────────────

  static const _expenseIcons = <String, Object>{
    'Food & Drinks': PhosphorIconsDuotone.forkKnife,
    'Groceries': PhosphorIconsDuotone.shoppingCart,
    'Transport': PhosphorIconsDuotone.bus,
    'Car': PhosphorIconsDuotone.car,
    'Shopping': PhosphorIconsDuotone.shoppingBag,
    'Bills & Fees': PhosphorIconsDuotone.lightning,
    'Health': PhosphorIconsDuotone.heartbeat,
    'Entertainment': PhosphorIconsDuotone.filmSlate,
    'Travel': PhosphorIconsDuotone.airplaneTilt,
    'Investments': PhosphorIconsDuotone.trendUp,
    'Education': PhosphorIconsDuotone.graduationCap,
    'Subscriptions': PhosphorIconsDuotone.repeat,
    'Gifts': PhosphorIconsDuotone.gift,
    'Others': PhosphorIconsDuotone.tag,
  };

  static const _incomeCats = <(String, Object)>[
    ('Salary', PhosphorIconsDuotone.briefcase),
    ('Freelance', PhosphorIconsDuotone.laptop),
    ('Business', PhosphorIconsDuotone.storefront),
    ('Interest', PhosphorIconsDuotone.percent),
    ('Investments', PhosphorIconsDuotone.trendUp),
    ('Refund', PhosphorIconsDuotone.arrowCounterClockwise),
    ('Gifts', PhosphorIconsDuotone.gift),
    ('Others', PhosphorIconsDuotone.tag),
  ];

  /// Categories for the current type, most-used first (then onboarding picks).
  List<_Cat> _orderedCats(bool isExpense) {
    final home = Get.find<HomeController>();
    final base = isExpense
        ? categoryList
            .map((c) => _Cat(
                c.name,
                _expenseIcons[c.name] ?? PhosphorIconsDuotone.tag,
                AppColor.categoryColor(c.name)))
            .toList()
        : _incomeCats
            .map((c) => _Cat(c.$1, c.$2, AppColor.categoryColor(c.$1)))
            .toList();

    final type = isExpense ? 'expense' : 'income';
    final uses = <String, int>{};
    for (final t in home.allTransactions) {
      if (t['type'] != type) continue;
      final c = t['category'] as String?;
      if (c != null) uses[c] = (uses[c] ?? 0) + 1;
    }
    final preferred = home.selectedCategories;
    int rank(_Cat c) =>
        (uses[c.name] ?? 0) * 10 + (preferred.contains(c.name) ? 5 : 0);
    final sorted = [...base]..sort((a, b) => rank(b).compareTo(rank(a)));
    return sorted;
  }

  void _showAllCategories(List<_Cat> cats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, 24 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            const SizedBox(height: 16),
            Text('All categories',
                style: GoogleFonts.urbanist(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColor.heading)),
            const SizedBox(height: 14),
            Obx(() => GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.82,
                  children: cats
                      .map((c) => _CategoryTile(
                            cat: c,
                            selected:
                                controller.selectedCategory.value == c.name,
                            onTap: () {
                              controller.selectedCategory.value = c.name;
                              Navigator.pop(sheetCtx);
                            },
                          ))
                      .toList(),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Obx(() {
      final isExpense = _isExpense.value;
      final cats = _orderedCats(isExpense);
      final selected = controller.selectedCategory.value;
      // Keep the selected category visible even if it's not in the top 7
      var shown = cats.take(7).toList();
      if (selected.isNotEmpty && !shown.any((c) => c.name == selected)) {
        final sel = cats.where((c) => c.name == selected);
        if (sel.isNotEmpty) shown = [sel.first, ...shown.take(6)];
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          childAspectRatio: 1.12,
          children: [
            ...shown.map((c) => _CategoryTile(
                  cat: c,
                  selected: selected == c.name,
                  onTap: () => controller.selectedCategory.value = c.name,
                )),
            _CategoryTile(
              cat: const _Cat('More', PhosphorIconsDuotone.dotsThreeOutline,
                  AppColor.textSecondary),
              selected: false,
              onTap: () => _showAllCategories(cats),
            ),
          ],
        ),
      );
    });
  }

  // ── Date + note ───────────────────────────────────────────────────────────

  Widget _buildDateAndNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Obx(() {
            final current = DateTime.tryParse(controller.selectedDate.value) ??
                DateTime.now();
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final day = DateTime(current.year, current.month, current.day);
            final label = day == today
                ? 'Today'
                : day == today.subtract(const Duration(days: 1))
                    ? 'Yesterday'
                    : DateFormat('d MMM').format(current);
            return PopupMenuButton<int>(
              offset: const Offset(0, -150),
              color: AppColor.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                HapticFeedback.selectionClick();
                if (v == 0)
                  controller.selectedDate.value = now.toIso8601String();
                if (v == 1) {
                  controller.selectedDate.value =
                      now.subtract(const Duration(days: 1)).toIso8601String();
                }
                if (v == 2) _selectDate(context);
              },
              itemBuilder: (_) => [
                for (final (i, t) in [
                  (0, 'Today'),
                  (1, 'Yesterday'),
                  (2, 'Pick a date…')
                ])
                  PopupMenuItem(
                    value: i,
                    child: Text(t,
                        style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary)),
                  ),
              ],
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColor.borderStrong),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PhosphorIcon(PhosphorIconsDuotone.calendarBlank,
                        size: 17,
                        color: AppColor.primary,
                        duotoneSecondaryOpacity: 0.3),
                    const SizedBox(width: 6),
                    Text(label,
                        style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary)),
                    const SizedBox(width: 2),
                    const PhosphorIcon(PhosphorIconsBold.caretDown,
                        size: 11, color: AppColor.textTertiary),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _noteFocus.hasFocus
                      ? AppColor.primary
                      : AppColor.borderStrong,
                  width: _noteFocus.hasFocus ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  PhosphorIcon(PhosphorIconsLight.pencilSimpleLine,
                      size: 16,
                      color: _noteFocus.hasFocus
                          ? AppColor.primary
                          : AppColor.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => TextField(
                          controller: controller.titleController,
                          focusNode: _noteFocus,
                          textCapitalization: TextCapitalization.sentences,
                          onTap: _scrollToBottom,
                          style: GoogleFonts.urbanist(
                              color: AppColor.textPrimary, fontSize: 14),
                          cursorColor: AppColor.primary,
                          decoration: InputDecoration(
                            hintText:
                                _isExpense.value ? 'Add a note' : 'From where?',
                            hintStyle: GoogleFonts.urbanist(
                                color: AppColor.textTertiary, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save button with a reward preview ─────────────────────────────────────

  Widget _buildSaveButton() {
    return Obx(() {
      final isLoading = controller.isLoading.isTrue;
      final ready = _amount.value.isNotEmpty &&
          (double.tryParse(_amount.value) ?? 0) > 0 &&
          controller.selectedCategory.value.isNotEmpty;
      final isExpense = _isExpense.value;

      String? reward;
      if (!_isEditMode) {
        final p = ProgressService.compute(
          transactions: Get.find<HomeController>().allTransactions.toList(),
        );
        final now = DateTime.now();
        final todayCount =
            Get.find<HomeController>().allTransactions.where((t) {
          final raw = t['created_at'] ?? t['date'];
          final d = raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
          return d != null &&
              d.year == now.year &&
              d.month == now.month &&
              d.day == now.day;
        }).length;
        final xp = todayCount >= ProgressService.maxEntriesPerDay
            ? 0
            : ProgressService.xpPerEntry +
                (p.loggedToday ? 0 : ProgressService.dailyBonus);
        final streakNote = !p.loggedToday && p.streak > 0
            ? ' · keeps your ${p.streak}-day streak'
            : !p.loggedToday
                ? ' · starts a streak'
                : '';
        if (xp > 0) reward = '+$xp XP$streakNote';
      }

      final hasAmount = (double.tryParse(_amount.value) ?? 0) > 0;
      final label = !hasAmount
          ? 'Enter an amount'
          : controller.selectedCategory.value.isEmpty
              ? 'Pick a category'
              : _isEditMode
                  ? 'Save changes'
                  : (isExpense ? 'Add expense' : 'Add income');
      if (!ready) reward = null;

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: GestureDetector(
          onTap: isLoading || !ready ? null : _submit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: ready ? AppColor.primary : AppColor.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
              boxShadow: ready
                  ? [
                      BoxShadow(
                        color: AppColor.primary.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.urbanist(
                            color:
                                ready ? Colors.white : AppColor.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (reward != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PhosphorIcon(PhosphorIconsFill.lightning,
                                  size: 11, color: Color(0xFFF2C27B)),
                              const SizedBox(width: 3),
                              Text(
                                reward,
                                style: GoogleFonts.urbanist(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final noteActive = _noteFocus.hasFocus && keyboardVisible;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    _CircleBtn(
                      icon: _isEditMode
                          ? PhosphorIconsLight.arrowLeft
                          : PhosphorIconsLight.x,
                      onTap: Get.back,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Obx(() => _TypeSwitch(
                              isExpense: _isExpense.value,
                              onChanged: (v) {
                                if (v == _isExpense.value) return;
                                _setType(v);
                                controller.selectedCategory.value = '';
                              },
                            )),
                      ),
                    ),
                    _CircleBtn(
                      icon: PhosphorIconsLight.microphone,
                      onTap: _startVoiceInput,
                      highlight: true,
                    ),
                  ],
                ),
              ),

              // ── Amount: centred in whatever space is left ─────────────
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Amount ────────────────────────────────────────
                        Obx(() {
                          final sym =
                              Get.find<HomeController>().currencySymbol.value;
                          final empty = _amount.value.isEmpty;
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(_amount.value),
                            tween: Tween(begin: empty ? 1 : 1.06, end: 1),
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            builder: (_, s, c) =>
                                Transform.scale(scale: s, child: c),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width - 48),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    // ₹ sits on the same baseline as the number
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        sym,
                                        style: GoogleFonts.urbanist(
                                          color: empty
                                              ? AppColor.textTertiary
                                              : AppColor.textSecondary,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IntrinsicWidth(
                                        child: TextField(
                                          controller:
                                              controller.amountController,
                                          focusNode: _amountFocus,
                                          readOnly: true,
                                          showCursor: true,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.urbanist(
                                            color: AppColor.textPrimary,
                                            fontSize: 54,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -2,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
                                          cursorColor: AppColor.primary,
                                          cursorWidth: 2.5,
                                          cursorHeight: 52,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            filled: false,
                                            contentPadding: EdgeInsets.zero,
                                            isCollapsed: true,
                                            hintText: '0',
                                            hintStyle: GoogleFonts.urbanist(
                                              color: AppColor.textTertiary
                                                  .withValues(alpha: 0.5),
                                              fontSize: 54,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                        // Selected category chip — only takes space once a category is picked
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: Obx(() {
                            final name = controller.selectedCategory.value;
                            if (name.isEmpty) return const SizedBox(width: 1);
                            final cat = _orderedCats(_isExpense.value)
                                .firstWhereOrNull((c) => c.name == name);
                            final color = cat?.color ?? AppColor.primary;
                            return TweenAnimationBuilder<double>(
                              key: ValueKey(name),
                              tween: Tween(begin: 0.8, end: 1),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              builder: (_, s, c) =>
                                  Transform.scale(scale: s, child: c),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(5, 4, 12, 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                          color: color, shape: BoxShape.circle),
                                      child: Center(
                                        child: PhosphorIcon(
                                            cat?.icon ??
                                                PhosphorIconsDuotone.tag,
                                            size: 12,
                                            color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(name,
                                        style: GoogleFonts.urbanist(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: color)),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Categories, date & note sit just above the button ─────
              if (!noteActive) _buildCategories(),
              const SizedBox(height: 8),
              _buildDateAndNote(),
              const SizedBox(height: 4),

              _buildSaveButton(),
              // Custom numpad (hidden while typing a note)
              if (!noteActive) _Numpad(onKey: _tapKey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(controller.selectedDate.value) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColor.primary,
            onSurface: AppColor.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final now = DateTime.now();
      // Keep the current time so same-day entries stay in logging order
      controller.selectedDate.value =
          DateTime(picked.year, picked.month, picked.day, now.hour, now.minute)
              .toIso8601String();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data

class _Cat {
  final String name;
  final Object icon; // Phosphor duotone icon
  final Color color;
  const _Cat(this.name, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// Header pieces

class _CircleBtn extends StatelessWidget {
  final PhosphorIconData icon;
  final VoidCallback onTap;
  final bool highlight;
  const _CircleBtn(
      {required this.icon, required this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: highlight ? AppColor.primaryExtraSoft : AppColor.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColor.borderStrong),
          ),
          child: Center(
            child: PhosphorIcon(icon,
                size: 19,
                color: highlight ? AppColor.primary : AppColor.textPrimary),
          ),
        ),
      );
}

class _TypeSwitch extends StatelessWidget {
  final bool isExpense;
  final ValueChanged<bool> onChanged;
  const _TypeSwitch({required this.isExpense, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColor.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Stack(
        children: [
          // Sliding highlight — exactly half the inner width
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: isExpense ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withValues(alpha: 0.12),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (label, value, color) in [
                ('Expense', true, AppColor.expense),
                ('Income', false, AppColor.income),
              ])
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(value),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isExpense == value
                                  ? color
                                  : AppColor.textTertiary
                                      .withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              height: 1,
                              fontWeight: isExpense == value
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isExpense == value
                                  ? AppColor.textPrimary
                                  : AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category tile

class _CategoryTile extends StatelessWidget {
  final _Cat cat;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryTile(
      {required this.cat, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      selected ? cat.color : cat.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColor.surface : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: cat.color.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: PhosphorIcon(
                    cat.icon,
                    size: 22,
                    color: selected ? Colors.white : cat.color,
                    duotoneSecondaryOpacity: selected ? 0.4 : 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              cat.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColor.textPrimary : AppColor.textSecondary,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom numpad

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onKey;
  const _Numpad({required this.onKey});

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _keys
            .map((row) => Row(
                  children: row
                      .map((key) => Expanded(
                          child: _NumKey(label: key, onTap: () => onKey(key))))
                      .toList(),
                ))
            .toList(),
      ),
    );
  }
}

class _NumKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NumKey({required this.label, required this.onTap});

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isBackspace = widget.label == '⌫';
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() => _down = true);
          widget.onTap();
        },
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: SizedBox(
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: _down ? 64 : 40,
                height: _down ? 48 : 30,
                decoration: BoxDecoration(
                  color: _down ? AppColor.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              isBackspace
                  ? const PhosphorIcon(PhosphorIconsLight.backspace,
                      color: AppColor.textPrimary, size: 24)
                  : Text(
                      widget.label,
                      style: GoogleFonts.urbanist(
                        color: AppColor.textPrimary,
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Voice input bottom sheet

// ─────────────────────────────────────────────────────────────────────────────
// Voice sheet — real device with mic

class _VoiceSheet extends StatefulWidget {
  final bool isDark;
  final SpeechToText speech;
  final RxString voiceText;
  final RxBool isListening;

  const _VoiceSheet({
    required this.isDark,
    required this.speech,
    required this.voiceText,
    required this.isListening,
  });

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet>
    with TickerProviderStateMixin {
  late final AnimationController _pulse1;
  late final AnimationController _pulse2;
  // Curves: expand quickly, fade out slowly
  late final Animation<double> _scale1;
  late final Animation<double> _alpha1;
  late final Animation<double> _scale2;
  late final Animation<double> _alpha2;

  @override
  void initState() {
    super.initState();
    _pulse1 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
    _pulse2 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _pulse2.repeat();
      }
    });

    _scale1 = Tween(begin: 1.0, end: 2.2)
        .animate(CurvedAnimation(parent: _pulse1, curve: Curves.easeOut));
    _alpha1 = Tween(begin: 0.55, end: 0.0)
        .animate(CurvedAnimation(parent: _pulse1, curve: Curves.easeIn));
    _scale2 = Tween(begin: 1.0, end: 2.2)
        .animate(CurvedAnimation(parent: _pulse2, curve: Curves.easeOut));
    _alpha2 = Tween(begin: 0.55, end: 0.0)
        .animate(CurvedAnimation(parent: _pulse2, curve: Curves.easeIn));

    _startListening();
  }

  @override
  void dispose() {
    _pulse1.dispose();
    _pulse2.dispose();
    if (widget.speech.isListening) {
      widget.speech.stop();
    }
    super.dispose();
  }

  void _startListening() {
    widget.speech.listen(
      onResult: (result) => widget.voiceText.value = result.recognizedWords,
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_IN',
      listenOptions:
          SpeechListenOptions(cancelOnError: true, partialResults: true),
    );
    widget.isListening.value = true;
  }

  Future<void> _stop() async {
    await widget.speech.stop();
    widget.isListening.value = false;
    if (mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        widget.isDark ? AppColor.textPrimary : AppColor.textPrimary;
    final textMuted =
        widget.isDark ? AppColor.textSecondary : AppColor.textSecondary;
    final transcriptBg =
        widget.isDark ? AppColor.darkCard : AppColor.surfaceVariant;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColor.darkBorder : AppColor.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Mic with radiating pulse rings
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse ring 2 (offset start)
                  AnimatedBuilder(
                    animation: _pulse2,
                    builder: (_, __) => Transform.scale(
                      scale: _scale2.value,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppColor.primary.withValues(alpha: _alpha2.value),
                        ),
                      ),
                    ),
                  ),
                  // Pulse ring 1
                  AnimatedBuilder(
                    animation: _pulse1,
                    builder: (_, __) => Transform.scale(
                      scale: _scale1.value,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppColor.primary.withValues(alpha: _alpha1.value),
                        ),
                      ),
                    ),
                  ),
                  // Solid mic button
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColor.primaryGradient,
                    ),
                    child: const Center(
                      child: PhosphorIcon(PhosphorIconsLight.microphone,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Listening…',
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Speak naturally — amount, place, category',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13)),
            const SizedBox(height: 18),

            // Live transcript
            Obx(() {
              final text = widget.voiceText.value;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 56),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: transcriptBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: text.isNotEmpty
                        ? AppColor.primary.withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  text.isEmpty ? 'Start speaking…' : text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: text.isEmpty ? textMuted : textPrimary,
                    fontSize: text.isEmpty ? 14 : 16,
                    fontWeight:
                        text.isEmpty ? FontWeight.w400 : FontWeight.w600,
                    fontStyle:
                        text.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Done button
            GestureDetector(
              onTap: _stop,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('Done',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text input sheet — simulator / no mic fallback

class _TextInputSheet extends StatefulWidget {
  final bool isDark;
  final RxString voiceText;

  const _TextInputSheet({required this.isDark, required this.voiceText});

  @override
  State<_TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends State<_TextInputSheet> {
  late final TextEditingController _tc;

  static const _examples = [
    '₹200 Zomato',
    '500 petrol',
    '1000 groceries',
    'Netflix 649',
    '250 auto'
  ];

  @override
  void initState() {
    super.initState();
    _tc = TextEditingController();
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _apply() {
    final t = _tc.text.trim();
    if (t.isEmpty) {
      return;
    }
    widget.voiceText.value = t;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        widget.isDark ? AppColor.textPrimary : AppColor.textPrimary;
    final textMuted =
        widget.isDark ? AppColor.textSecondary : AppColor.textSecondary;
    final inputBg = widget.isDark ? AppColor.darkCard : AppColor.surfaceVariant;
    final chipBg = widget.isDark ? AppColor.darkCard : AppColor.surfaceVariant;
    final border = widget.isDark ? AppColor.darkBorder : AppColor.border;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColor.darkBorder : AppColor.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Icon + title row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColor.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: PhosphorIcon(PhosphorIconsLight.microphone,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Add',
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  Text('Describe in plain words',
                      style: TextStyle(color: textMuted, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Text field
          TextField(
            controller: _tc,
            autofocus: true,
            style: TextStyle(color: textPrimary, fontSize: 15),
            cursorColor: AppColor.primary,
            onSubmitted: (_) => _apply(),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'e.g. 200 Zomato or 500 petrol',
              hintStyle: TextStyle(color: textMuted, fontSize: 14),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColor.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: PhosphorIcon(PhosphorIconsLight.xCircle,
                    color: textMuted, size: 18),
                onPressed: _tc.clear,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Example chips
          Text('Try these:',
              style: TextStyle(
                  color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _examples
                .map((e) => GestureDetector(
                      onTap: () => setState(() => _tc.text = e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                        ),
                        child: Text(e,
                            style: TextStyle(color: textPrimary, fontSize: 13)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          // Apply button
          GestureDetector(
            onTap: _apply,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColor.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Parse & Fill',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
