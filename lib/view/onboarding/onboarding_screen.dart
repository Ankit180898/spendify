import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/onboarding/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(OnboardingController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? AppColor.darkBg : Colors.white,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Obx(() => ctrl.currentStep.value > 0
                        ? GestureDetector(
                            onTap: ctrl.previousStep,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColor.darkSurface
                                    : AppColor.lightSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: isDark
                                        ? AppColor.darkBorder
                                        : AppColor.lightBorder,
                                    width: 1),
                              ),
                              child: PhosphorIcon(
                                PhosphorIconsLight.arrowLeft,
                                color: isDark
                                    ? AppColor.textPrimary
                                    : AppColor.lightTextPrimary,
                                size: 18,
                              ),
                            ),
                          )
                        : const SizedBox(width: 38)),
                    const Spacer(),
                    GestureDetector(
                      onTap: ctrl.skip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark
                              ? AppColor.textSecondary
                              : AppColor.lightTextSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress dots ──────────────────────────────────────────
              Obx(() => _ProgressDots(
                    current: ctrl.currentStep.value,
                    total: OnboardingController.totalSteps,
                    isDark: isDark,
                  )),

              const SizedBox(height: 8),

              // ── Pages ─────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: ctrl.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _CurrencyStep(isDark: isDark),
                    _OccupationStep(isDark: isDark),
                    _BudgetStep(isDark: isDark),
                    _CategoriesStep(isDark: isDark),
                  ],
                ),
              ),

              // ── CTA button ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Obx(() {
                  final isLast = ctrl.currentStep.value ==
                      OnboardingController.totalSteps - 1;
                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          ctrl.isSaving.value ? null : ctrl.nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColor.primary.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: ctrl.isSaving.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isLast ? 'Get Started' : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Progress dots ─────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final int current;
  final int total;
  final bool isDark;

  const _ProgressDots(
      {required this.current, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? AppColor.primary
                : (isDark ? AppColor.darkBorder : AppColor.lightBorder),
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}

// ── Step scaffold ─────────────────────────────────────────────────────────────

class _StepScaffold extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget child;
  final bool isDark;

  const _StepScaffold({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppColor.textPrimary : AppColor.lightTextPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color:
                  isDark ? AppColor.textSecondary : AppColor.lightTextSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Step 1 — Currency ─────────────────────────────────────────────────────────

class _CurrencyStep extends StatelessWidget {
  final bool isDark;
  const _CurrencyStep({required this.isDark});

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
    final ctrl = Get.find<OnboardingController>();
    final surfaceColor =
        isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final borderColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textColor =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final subTextColor =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return _StepScaffold(
      isDark: isDark,
      emoji: '💱',
      title: 'What currency\ndo you use?',
      subtitle: 'We\'ll use this for all your\ntransactions and budgets.',
      child: Obx(() {
        final selectedCurrency = ctrl.currency.value;
        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
          ),
          itemCount: _currencies.length,
          itemBuilder: (_, i) {
            final (code, symbol, name, flag) = _currencies[i];
            final isSelected = selectedCurrency == code;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ctrl.selectCurrency(code, symbol);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primary.withValues(alpha: 0.15)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColor.primary : borderColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$code $symbol',
                            style: TextStyle(
                              color: isSelected ? AppColor.primary : textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            name,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
}

// ── Step 2 — Occupation ───────────────────────────────────────────────────────

class _OccupationStep extends StatelessWidget {
  final bool isDark;
  const _OccupationStep({required this.isDark});

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
    final ctrl = Get.find<OnboardingController>();
    final surfaceColor =
        isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final borderColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textColor =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final subTextColor =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return _StepScaffold(
      isDark: isDark,
      emoji: '💼',
      title: 'What do you\ndo for a living?',
      subtitle: 'This helps us tailor budget\nsuggestions for you.',
      child: Obx(() {
        final selectedOccupation = ctrl.occupation.value;
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: _occupations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final (label, icon) = _occupations[i];
            final isSelected = selectedOccupation == label;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ctrl.selectOccupation(label);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primary.withValues(alpha: 0.12)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColor.primary : borderColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    PhosphorIcon(
                      icon,
                      color:
                          isSelected ? AppColor.primary : subTextColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? textColor : subTextColor,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColor.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const PhosphorIcon(
                          PhosphorIconsLight.check,
                          color: Colors.white,
                          size: 12,
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
}

// ── Budget amount field ────────────────────────────────────────────────────────

class _BudgetField extends StatefulWidget {
  final OnboardingController ctrl;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color hintColor;

  const _BudgetField({
    required this.ctrl,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.hintColor,
  });

  @override
  State<_BudgetField> createState() => _BudgetFieldState();
}

class _BudgetFieldState extends State<_BudgetField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: widget.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? AppColor.primary : widget.borderColor,
            width: _focused ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.ctrl.currencySymbol.value,
              style: TextStyle(
                color: _focused ? AppColor.primary : widget.textColor,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.ctrl.budgetController,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: widget.hintColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  isDense: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
              ),
            ),
          ],
        ),
      ));
}

// ── Step 3 — Monthly budget ───────────────────────────────────────────────────

class _BudgetStep extends StatelessWidget {
  final bool isDark;
  const _BudgetStep({required this.isDark});

  static const _quickAmounts = [
    '10,000',
    '20,000',
    '30,000',
    '50,000',
    '75,000',
    '1,00,000',
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    final surfaceColor =
        isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final borderColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textColor =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final hintColor =
        isDark ? AppColor.textTertiary : AppColor.lightTextTertiary;
    final subTextColor =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return _StepScaffold(
      isDark: isDark,
      emoji: '🎯',
      title: 'Set your monthly\nspending budget',
      subtitle: 'How much do you typically\nspend each month?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount input
          _BudgetField(
            ctrl: ctrl,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            hintColor: hintColor,
          ),

          const SizedBox(height: 20),

          Text(
            'Quick select',
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Quick amount chips
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
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColor.primary.withValues(alpha: 0.15)
                          : surfaceColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? AppColor.primary : borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${ctrl.currencySymbol.value}$amt',
                      style: TextStyle(
                        color: isSelected ? AppColor.primary : subTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

// ── Step 4 — Categories ───────────────────────────────────────────────────────

class _CatItem {
  final String label;
  final PhosphorIconData icon;
  final Color color;

  const _CatItem(this.label, this.icon, this.color);
}

class _CategoriesStep extends StatelessWidget {
  final bool isDark;
  const _CategoriesStep({required this.isDark});

  static const _cats = [
    _CatItem('Food & Drinks', PhosphorIconsLight.coffee, Color(0xFFEAB308)),
    _CatItem(
        'Groceries', PhosphorIconsLight.shoppingCart, Color(0xFF22C55E)),
    _CatItem('Transport', PhosphorIconsLight.bus, Color(0xFF8B5CF6)),
    _CatItem(
        'Bills & Fees', PhosphorIconsLight.receipt, Color(0xFFF97316)),
    _CatItem('Health', PhosphorIconsLight.heart, Color(0xFFEF4444)),
    _CatItem('Car', PhosphorIconsLight.car, Color(0xFF6366F1)),
    _CatItem(
        'Shopping', PhosphorIconsLight.shoppingBag, Color(0xFFEC4899)),
    _CatItem(
        'Entertainment', PhosphorIconsLight.popcorn, Color(0xFF14B8A6)),
    _CatItem(
        'Investments', PhosphorIconsLight.chartBar, Color(0xFF3B82F6)),
    _CatItem(
        'Education', PhosphorIconsLight.graduationCap, Color(0xFF8B5CF6)),
    _CatItem(
        'Travel', PhosphorIconsLight.airplaneTakeoff, Color(0xFF06B6D4)),
    _CatItem('Gifts', PhosphorIconsLight.gift, Color(0xFFFF7849)),
    _CatItem(
        'Subscriptions', PhosphorIconsLight.infinity, Color(0xFFA855F7)),
    _CatItem('Others', PhosphorIconsLight.squaresFour, Color(0xFF71717A)),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    final surfaceColor =
        isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final borderColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final textColor =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final subTextColor =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return _StepScaffold(
      isDark: isDark,
      emoji: '🗂️',
      title: 'Pick your\ntop categories',
      subtitle: 'Select the ones you spend\non most. You can change later.',
      child: Obx(() {
        final selected = ctrl.selectedCategories.toList();
        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
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
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cat.color.withValues(alpha: 0.12)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? cat.color : borderColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: PhosphorIcon(
                        cat.icon,
                        color: cat.color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          color: isSelected ? textColor : subTextColor,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
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
}
