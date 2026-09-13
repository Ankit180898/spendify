import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/onboarding/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(OnboardingController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Obx(() => ctrl.currentStep.value > 0
                        ? GestureDetector(
                            onTap: ctrl.previousStep,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColor.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColor.border),
                              ),
                              child: const Center(
                                child: PhosphorIcon(
                                  PhosphorIconsLight.arrowLeft,
                                  color: AppColor.textPrimary,
                                  size: 18,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(width: 38)),
                    const Spacer(),
                    GestureDetector(
                      onTap: ctrl.skip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColor.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColor.border),
                        ),
                        child: Text(
                          'Skip',
                          style: AppTypography.captionSemiBold(
                              AppColor.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Step dots ────────────────────────────────────────────
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      OnboardingController.totalSteps,
                      (i) {
                        final isActive = i == ctrl.currentStep.value;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColor.primary
                                : AppColor.border,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        );
                      },
                    ),
                  )),

              const SizedBox(height: 4),

              // ── Pages ────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: ctrl.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _CurrencyStep(),
                    _OccupationStep(),
                    _BudgetStep(),
                    _CategoriesStep(),
                  ],
                ),
              ),

              // ── CTA ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Obx(() {
                  final isLast = ctrl.currentStep.value ==
                      OnboardingController.totalSteps - 1;
                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: ctrl.isSaving.value ? null : ctrl.nextStep,
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
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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

// ── Step scaffold ─────────────────────────────────────────────────────────────

class _StepScaffold extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  const _StepScaffold({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero banner ───────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 56)),
          ),
        ),

        // ── Title + subtitle ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
          child: Text(
            title,
            style: GoogleFonts.urbanist(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColor.textPrimary,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text(
            subtitle,
            style: AppTypography.body(AppColor.textSecondary),
          ),
        ),

        // ── Content ───────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
        ),
      ],
    );
  }
}

// ── Step 1 — Currency ─────────────────────────────────────────────────────────

class _CurrencyStep extends StatelessWidget {
  const _CurrencyStep();

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

    return _StepScaffold(
      emoji: '💱',
      title: 'What currency\ndo you use?',
      subtitle: 'Used for all transactions and budgets.',
      accent: AppColor.primary,
      child: Obx(() {
        final selected = ctrl.currency.value;
        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primary.withValues(alpha: 0.08)
                      : AppColor.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColor.primary
                        : AppColor.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$code $symbol',
                            style: GoogleFonts.urbanist(
                              color: isSelected
                                  ? AppColor.primary
                                  : AppColor.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            name,
                            style: AppTypography.caption(AppColor.textTertiary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColor.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: PhosphorIcon(
                            PhosphorIconsLight.check,
                            color: Colors.white,
                            size: 10,
                          ),
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
  const _OccupationStep();

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

  static const _accent = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();

    return _StepScaffold(
      emoji: '💼',
      title: 'What do you\ndo for a living?',
      subtitle: 'Helps us tailor budget suggestions for you.',
      accent: _accent,
      child: Obx(() {
        final selected = ctrl.occupation.value;
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: _occupations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final (label, icon) = _occupations[i];
            final isSelected = selected == label;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ctrl.selectOccupation(label);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _accent.withValues(alpha: 0.08)
                      : AppColor.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _accent : AppColor.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _accent.withValues(alpha: 0.12)
                            : AppColor.surfaceVariant,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          icon,
                          color: isSelected ? _accent : AppColor.textSecondary,
                          size: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.urbanist(
                          color: isSelected
                              ? AppColor.textPrimary
                              : AppColor.textSecondary,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: PhosphorIcon(
                            PhosphorIconsLight.check,
                            color: Colors.white,
                            size: 11,
                          ),
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

// ── Budget field ──────────────────────────────────────────────────────────────

class _BudgetField extends StatefulWidget {
  final OnboardingController ctrl;
  const _BudgetField({required this.ctrl});

  @override
  State<_BudgetField> createState() => _BudgetFieldState();
}

class _BudgetFieldState extends State<_BudgetField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
        () => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? AppColor.income : AppColor.border,
            width: _focused ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(
              widget.ctrl.currencySymbol.value,
              style: GoogleFonts.urbanist(
                color: _focused ? AppColor.income : AppColor.textSecondary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.ctrl.budgetController,
                focusNode: _focusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.urbanist(
                  color: AppColor.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.urbanist(
                    color: AppColor.textTertiary,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: false,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16),
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
  const _BudgetStep();

  static const _quickAmounts = [
    '10,000', '20,000', '30,000',
    '50,000', '75,000', '1,00,000',
  ];

  static const _accent = AppColor.income;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();

    return _StepScaffold(
      emoji: '🎯',
      title: 'Set your monthly\nspending budget',
      subtitle: 'How much do you typically spend each month?',
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BudgetField(ctrl: ctrl),
          const SizedBox(height: 16),
          Text(
            'Quick select',
            style: AppTypography.captionSemiBold(AppColor.textTertiary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                          ? _accent.withValues(alpha: 0.10)
                          : AppColor.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? _accent : AppColor.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${ctrl.currencySymbol.value}$amt',
                      style: GoogleFonts.urbanist(
                        color: isSelected ? _accent : AppColor.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
  const _CategoriesStep();

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

  static const _accent = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();

    return _StepScaffold(
      emoji: '🗂️',
      title: 'Pick your\ntop categories',
      subtitle: 'Select what you spend on most. Change anytime.',
      accent: _accent,
      child: Obx(() {
        final selected = ctrl.selectedCategories.toList();
        return GridView.builder(
          padding: EdgeInsets.zero,
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cat.color.withValues(alpha: 0.08)
                      : AppColor.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? cat.color : AppColor.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: PhosphorIcon(cat.icon,
                            color: cat.color, size: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.label,
                        style: GoogleFonts.urbanist(
                          color: isSelected
                              ? AppColor.textPrimary
                              : AppColor.textSecondary,
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
