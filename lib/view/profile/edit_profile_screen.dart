import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/edit_profile/edit_profile_controller.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(EditProfileController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textMuted =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Edit Preferences',
            style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIconsLight.arrowLeft,
              color: textPrimary, size: 22),
          onPressed: Get.back,
        ),
        actions: [
          Obx(() => TextButton(
                onPressed: ctrl.isSaving.value ? null : ctrl.save,
                child: ctrl.isSaving.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColor.primary))
                    : const Text('Save',
                        style: TextStyle(
                            color: AppColor.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
              )),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColor.primary));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Currency ──────────────────────────────────
              _SectionHeader(label: 'Currency', textMuted: textMuted),
              _CurrencySection(isDark: isDark, ctrl: ctrl),

              Divider(height: 32, color: divColor),

              // ── Occupation ────────────────────────────────
              _SectionHeader(label: 'Occupation', textMuted: textMuted),
              _OccupationSection(isDark: isDark, ctrl: ctrl),

              Divider(height: 32, color: divColor),

              // ── Monthly budget ────────────────────────────
              _SectionHeader(label: 'Monthly Budget', textMuted: textMuted),
              _BudgetSection(isDark: isDark, ctrl: ctrl),

              Divider(height: 32, color: divColor),

              // ── Categories ────────────────────────────────
              _SectionHeader(label: 'Spending Categories', textMuted: textMuted),
              _CategoriesSection(isDark: isDark, ctrl: ctrl),
            ],
          ),
        );
      }),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color textMuted;
  const _SectionHeader({required this.label, required this.textMuted});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Text(label,
            style: TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3)),
      );
}

// ── Currency ──────────────────────────────────────────────────────────────────

class _CurrencySection extends StatelessWidget {
  final bool isDark;
  final EditProfileController ctrl;
  const _CurrencySection({required this.isDark, required this.ctrl});

  static const _currencies = [
    ('INR', '₹', 'Indian Rupee', '🇮🇳'),
    ('USD', '\$', 'US Dollar', '🇺🇸'),
    ('EUR', '€', 'Euro', '🇪🇺'),
    ('GBP', '£', 'British Pound', '🇬🇧'),
    ('AUD', 'A\$', 'Australian Dollar', '🇦🇺'),
    ('JPY', '¥', 'Japanese Yen', '🇯🇵'),
    ('SGD', 'S\$', 'Singapore Dollar', '🇸🇬'),
    ('AED', 'د.إ', 'UAE Dirham', '🇦🇪'),
  ];

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textColor = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final subText =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Obx(() {
      final selected = ctrl.currency.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.6,
          ),
          itemCount: _currencies.length,
          itemBuilder: (_, i) {
            final (code, symbol, name, flag) = _currencies[i];
            final isSelected = selected == code;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ctrl.selectCurrency(code, symbol);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primary.withValues(alpha: 0.12)
                      : surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isSelected ? AppColor.primary : border,
                      width: 1.5),
                ),
                child: Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$code $symbol',
                              style: TextStyle(
                                  color: isSelected
                                      ? AppColor.primary
                                      : textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          Text(name,
                              style:
                                  TextStyle(color: subText, fontSize: 9),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// ── Occupation ────────────────────────────────────────────────────────────────

class _OccupationSection extends StatelessWidget {
  final bool isDark;
  final EditProfileController ctrl;
  const _OccupationSection({required this.isDark, required this.ctrl});

  static const _occupations = [
    ('Salaried Employee', PhosphorIconsLight.briefcase),
    ('Self-employed', PhosphorIconsLight.buildings),
    ('Freelancer', PhosphorIconsLight.laptop),
    ('Student', PhosphorIconsLight.graduationCap),
    ('Business Owner', PhosphorIconsLight.storefront),
    ('Homemaker', PhosphorIconsLight.house),
    ('Retired', PhosphorIconsLight.sunHorizon),
    ('Other', PhosphorIconsLight.dotsThreeCircle),
  ];

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textColor = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final subText =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Obx(() {
      final selected = ctrl.occupation.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(_occupations.length, (i) {
            final (label, icon) = _occupations[i];
            final isSelected = selected == label;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < _occupations.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ctrl.selectOccupation(label);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColor.primary.withValues(alpha: 0.10)
                        : surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected ? AppColor.primary : border,
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(icon,
                          color: isSelected ? AppColor.primary : subText,
                          size: 20),
                      const SizedBox(width: 12),
                      Text(label,
                          style: TextStyle(
                              color: isSelected ? textColor : subText,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                      const Spacer(),
                      if (isSelected)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              color: AppColor.primary,
                              shape: BoxShape.circle),
                          child: const PhosphorIcon(
                              PhosphorIconsLight.check,
                              color: Colors.white,
                              size: 12),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}

// ── Budget ────────────────────────────────────────────────────────────────────

class _BudgetSection extends StatelessWidget {
  final bool isDark;
  final EditProfileController ctrl;
  const _BudgetSection({required this.isDark, required this.ctrl});

  static const _quickAmounts = [
    '10,000', '20,000', '30,000', '50,000', '75,000', '1,00,000',
  ];

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textColor = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final hintColor =
        isDark ? AppColor.textTertiary : AppColor.lightTextTertiary;
    final subText =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColor.primary, width: 1.5),
                ),
                child: Row(
                  children: [
                    Text(ctrl.currencySymbol.value,
                        style: const TextStyle(
                            color: AppColor.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: ctrl.budgetController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                              color: hintColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w400),
                          border: InputBorder.none,
                          isDense: false,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d,.]')),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Text('Quick select',
              style: TextStyle(
                  color: subText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickAmounts.map((amt) {
              return Obx(() {
                final isSelected = ctrl.budgetController.text == amt;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ctrl.budgetController.text = amt;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColor.primary.withValues(alpha: 0.12)
                          : surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: isSelected ? AppColor.primary : border,
                          width: 1.5),
                    ),
                    child: Text('${ctrl.currencySymbol.value}$amt',
                        style: TextStyle(
                            color: isSelected ? AppColor.primary : subText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                );
              });
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Categories ────────────────────────────────────────────────────────────────

class _CatItem {
  final String label;
  final PhosphorIconData icon;
  final Color color;
  const _CatItem(this.label, this.icon, this.color);
}

class _CategoriesSection extends StatelessWidget {
  final bool isDark;
  final EditProfileController ctrl;
  const _CategoriesSection({required this.isDark, required this.ctrl});

  static const _cats = [
    _CatItem('Food & Drinks', PhosphorIconsLight.coffee, Color(0xFFEAB308)),
    _CatItem('Groceries', PhosphorIconsLight.shoppingCart, Color(0xFF22C55E)),
    _CatItem('Transport', PhosphorIconsLight.bus, Color(0xFF8B5CF6)),
    _CatItem('Bills & Fees', PhosphorIconsLight.receipt, Color(0xFFF97316)),
    _CatItem('Health', PhosphorIconsLight.heart, Color(0xFFEF4444)),
    _CatItem('Car', PhosphorIconsLight.car, Color(0xFF6366F1)),
    _CatItem('Shopping', PhosphorIconsLight.shoppingBag, Color(0xFFEC4899)),
    _CatItem('Entertainment', PhosphorIconsLight.popcorn, Color(0xFF14B8A6)),
    _CatItem('Investments', PhosphorIconsLight.chartBar, Color(0xFF3B82F6)),
    _CatItem('Education', PhosphorIconsLight.graduationCap, Color(0xFF8B5CF6)),
    _CatItem('Travel', PhosphorIconsLight.airplaneTakeoff, Color(0xFF06B6D4)),
    _CatItem('Gifts', PhosphorIconsLight.gift, Color(0xFFFF7849)),
    _CatItem('Subscriptions', PhosphorIconsLight.infinity, Color(0xFFA855F7)),
    _CatItem('Others', PhosphorIconsLight.squaresFour, Color(0xFF71717A)),
  ];

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textColor = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final subText =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Obx(() {
      final selected = ctrl.selectedCategories.toList();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: _cats.length,
          itemBuilder: (_, i) {
            final cat = _cats[i];
            final isSelected = selected.contains(cat.label);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ctrl.toggleCategory(cat.label);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cat.color.withValues(alpha: 0.12)
                      : surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isSelected ? cat.color : border, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: PhosphorIcon(cat.icon,
                          color: cat.color, size: 15),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(cat.label,
                          style: TextStyle(
                              color: isSelected ? textColor : subText,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
