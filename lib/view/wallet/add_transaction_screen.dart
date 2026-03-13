import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';

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
  bool _noteVisible = false;

  bool get _isEditMode => widget.transaction != null;
  String get _transactionId => widget.transaction!['id'].toString();

  static const _cats = [
    _Cat('Food & Drinks', PhosphorIconsLight.coffee,       Color(0xFFEAB308)),
    _Cat('Groceries',     PhosphorIconsLight.shoppingCart, Color(0xFF22C55E)),
    _Cat('Transport',     PhosphorIconsLight.bus,           Color(0xFF8B5CF6)),
    _Cat('Bills & Fees',  PhosphorIconsLight.receipt,      Color(0xFFF97316)),
    _Cat('Health',        PhosphorIconsLight.heart,         Color(0xFFEF4444)),
    _Cat('Car',           PhosphorIconsLight.car,           Color(0xFF6366F1)),
    _Cat('Investments',   PhosphorIconsLight.chartBar,      Color(0xFF3B82F6)),
    _Cat('Gifts',         PhosphorIconsLight.gift,          Color(0xFFEC4899)),
    _Cat('Others',        PhosphorIconsLight.squaresFour,   Color(0xFF71717A)),
  ];

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
      if (note.isNotEmpty) _noteVisible = true;
    } else {
      controller.resetForm();
      controller.selectedType.value = widget.initialType;
    }
    _noteFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _noteFocus.dispose();
    super.dispose();
  }

  void _tapKey(String key) {
    HapticFeedback.lightImpact();
    final cur = _amount.value;
    if (key == '⌫') {
      if (cur.isNotEmpty) _amount.value = cur.substring(0, cur.length - 1);
    } else if (key == '.') {
      if (!cur.contains('.')) _amount.value = cur.isEmpty ? '0.' : cur + '.';
    } else {
      if (cur == '0') {
        _amount.value = key;
      } else {
        // Max 10 digits before decimal
        final parts = cur.split('.');
        if (parts[0].length < 10) _amount.value = cur + key;
      }
    }
    controller.amountController.text = _amount.value;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);
    final noteActive = _noteFocus.hasFocus;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: PhosphorIcon(PhosphorIconsLight.arrowLeft,
                                  color: textPrimary, size: 20),
                              onPressed: Get.back,
                            ),
                            Expanded(
                              child: Obx(() => Text(
                                    _isEditMode
                                        ? (_isExpense.value
                                            ? 'Edit Expense'
                                            : 'Edit Income')
                                        : (_isExpense.value
                                            ? 'Add Expense'
                                            : 'Add Income'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Type pills
                      Obx(() => _TypePills(
                            isExpense: _isExpense.value,
                            isDark: isDark,
                            onExpense: () => _setType(true),
                            onIncome: () => _setType(false),
                          )),
                      const SizedBox(height: 36),

                      // Amount
                      Obx(() {
                        final isExpense = _isExpense.value;
                        final accentColor =
                            isExpense ? AppColor.expense : AppColor.income;
                        final display = _amount.value.isEmpty
                            ? '0'
                            : _amount.value;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    Get.find<HomeController>().currencySymbol.value,
                                    style: TextStyle(
                                      color: accentColor.withValues(alpha: 0.5),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  display,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter Amount',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 28),

                      // Category chips
                      _buildCategoryRow(isDark, textMuted),
                      const SizedBox(height: 20),

                      // Date + Note rows
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Date
                            _buildInfoRow(
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                              divColor: divColor,
                              icon: PhosphorIconsLight.calendar,
                              label: Obx(() => Text(
                                    DateFormat('EEE, MMM d yyyy').format(
                                        DateTime.parse(
                                            controller.selectedDate.value)),
                                    style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  )),
                              trailing: PhosphorIcon(
                                  PhosphorIconsLight.caretRight,
                                  color: textMuted,
                                  size: 15),
                              onTap: () => _selectDate(context),
                            ),
                            Divider(height: 1, color: divColor),

                            // Note toggle / field
                            if (!_noteVisible)
                              _buildInfoRow(
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                divColor: divColor,
                                icon: PhosphorIconsLight.pencilSimple,
                                label: Text('Add a note',
                                    style: TextStyle(
                                        color: textMuted, fontSize: 14)),
                                trailing: PhosphorIcon(
                                    PhosphorIconsLight.plus,
                                    color: textMuted,
                                    size: 15),
                                onTap: () =>
                                    setState(() => _noteVisible = true),
                              )
                            else
                              _buildInfoRow(
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                divColor: divColor,
                                icon: PhosphorIconsLight.pencilSimple,
                                label: TextField(
                                  controller: controller.titleController,
                                  focusNode: _noteFocus,
                                  autofocus: true,
                                  style: TextStyle(
                                      color: textPrimary, fontSize: 14),
                                  cursorColor: AppColor.primary,
                                  decoration: InputDecoration(
                                    hintText: 'Type a note…',
                                    hintStyle: TextStyle(
                                        color: textMuted, fontSize: 14),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isCollapsed: true,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Save button ──────────────────────────────────────────────
              Obx(() {
                final isLoading = controller.isLoading.isTrue;
                final btnColor =
                    _isExpense.value ? AppColor.expense : AppColor.income;
                final label = _isEditMode
                    ? 'Save Changes'
                    : (_isExpense.value ? 'Add Expense' : 'Add Income');
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: GestureDetector(
                    onTap: isLoading ? null : _submit,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isLoading ? 0.6 : 1.0,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: btnColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(label,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // ── Custom numpad (hidden when note keyboard is up) ──────────
              if (!noteActive) _Numpad(onKey: _tapKey, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category horizontal scroll ────────────────────────────────────────────

  Widget _buildCategoryRow(bool isDark, Color textMuted) {
    final chipBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

    final preferred = Get.find<HomeController>().selectedCategories;
    final sortedCats = [
      ..._cats.where((c) => preferred.contains(c.name)),
      ..._cats.where((c) => !preferred.contains(c.name)),
    ];

    return SizedBox(
      height: 40,
      child: Obx(() {
        final selected = controller.selectedCategory.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: sortedCats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = sortedCats[i];
            final isSelected = selected == cat.name;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                controller.selectedCategory.value = cat.name;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                decoration: BoxDecoration(
                  color: isSelected ? cat.color.withValues(alpha: 0.1) : chipBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? cat.color : border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: PhosphorIcon(cat.icon,
                            color: cat.color, size: 12),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      cat.name.split(' ').first,
                      style: TextStyle(
                        color: isSelected ? cat.color : textMuted,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ── Info row (date / note) ────────────────────────────────────────────────

  Widget _buildInfoRow({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color divColor,
    required PhosphorIconData icon,
    required Widget label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            PhosphorIcon(icon, color: textMuted, size: 16),
            const SizedBox(width: 12),
            Expanded(child: label),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(controller.selectedDate.value),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: isDark
            ? ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColor.primary,
                  surface: AppColor.darkElevated,
                  onSurface: AppColor.textPrimary,
                ),
              )
            : ThemeData.light().copyWith(
                colorScheme:
                    const ColorScheme.light(primary: AppColor.primary),
              ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.selectedDate.value = picked.toIso8601String();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data

class _Cat {
  final String name;
  final PhosphorIconData icon;
  final Color color;
  const _Cat(this.name, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// Type pills

class _TypePills extends StatelessWidget {
  final bool isExpense;
  final bool isDark;
  final VoidCallback onExpense;
  final VoidCallback onIncome;

  const _TypePills({
    required this.isExpense,
    required this.isDark,
    required this.onExpense,
    required this.onIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Pill(
          label: 'Expenses',
          isSelected: isExpense,
          activeColor: AppColor.expense,
          isDark: isDark,
          onTap: onExpense,
        ),
        const SizedBox(width: 10),
        _Pill(
          label: 'Income',
          isSelected: !isExpense,
          activeColor: AppColor.income,
          isDark: isDark,
          onTap: onIncome,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveBg =
        isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final inactiveFg =
        isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : inactiveBg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : inactiveFg,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom numpad

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final bool isDark;

  const _Numpad({required this.onKey, required this.isDark});

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final keyBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final keyFg =
        isDark ? AppColor.textPrimary : const Color(0xFF09090B);

    return Container(
      color: isDark ? AppColor.darkBg : Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _keys.map((row) {
          return Row(
            children: row.map((key) {
              final isBackspace = key == '⌫';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: GestureDetector(
                    onTap: () => onKey(key),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: keyBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: isBackspace
                            ? PhosphorIcon(PhosphorIconsLight.backspace,
                                color: keyFg, size: 20)
                            : Text(
                                key,
                                style: TextStyle(
                                  color: keyFg,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
