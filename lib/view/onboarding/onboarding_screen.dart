import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/onboarding/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _ctaLabels = ['Continue', 'Continue', 'Continue', 'Finish setup'];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(OnboardingController());
    final bottom = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColor.bg,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Top bar: back · progress · skip ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Obx(() {
                  final step = ctrl.currentStep.value;
                  return Row(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: step > 0 ? 1 : 0,
                        child: IconButton(
                          onPressed: step > 0 ? ctrl.previousStep : null,
                          icon: const PhosphorIcon(PhosphorIconsBold.arrowLeft,
                              size: 18, color: AppColor.textPrimary),
                        ),
                      ),
                      Expanded(child: _SegmentedProgress(step: step)),
                      TextButton(
                        onPressed: ctrl.isSaving.value ? null : ctrl.skip,
                        child: Text('Skip',
                            style: AppTypography.bodySemiBold(AppColor.textSecondary)),
                      ),
                    ],
                  );
                }),
              ),

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
              Container(
                padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 20),
                decoration: BoxDecoration(
                  color: AppColor.bg,
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.bg.withValues(alpha: 0.9),
                      blurRadius: 16,
                      offset: const Offset(0, -12),
                    ),
                  ],
                ),
                child: Obx(() {
                  final step = ctrl.currentStep.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: ctrl.isSaving.value
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              FocusScope.of(context).unfocus();
                              ctrl.nextStep();
                            },
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: AppColor.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: ctrl.isSaving.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _ctaLabels[step],
                                  style: GoogleFonts.urbanist(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const PhosphorIcon(PhosphorIconsBold.arrowRight,
                                    size: 16, color: Colors.white),
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
    );
  }
}

// ── Progress ──────────────────────────────────────────────────────────────────

class _SegmentedProgress extends StatelessWidget {
  final int step;
  const _SegmentedProgress({required this.step});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(OnboardingController.totalSteps, (i) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppColor.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    widthFactor: i <= step ? 1 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'Step ${step + 1} of ${OnboardingController.totalSteps}',
            style: AppTypography.caption(AppColor.textTertiary),
          ),
        ],
      );
}

// ── Step scaffold ─────────────────────────────────────────────────────────────

class _StepScaffold extends StatelessWidget {
  final Object icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _StepScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, s, c) => Transform.scale(scale: s, alignment: Alignment.centerLeft, child: c),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColor.bannerBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColor.borderStrong),
              ),
              child: Center(
                child: PhosphorIcon(icon,
                    size: 28, color: AppColor.primary, duotoneSecondaryOpacity: 0.3),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
          child: Text(
            title,
            style: GoogleFonts.urbanist(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColor.textPrimary,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Text(
            subtitle,
            style: GoogleFonts.urbanist(
              fontSize: 15,
              color: AppColor.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// Outlined option tile with a mocha selected state and a check pip.
class _OptionTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  const _OptionTile({
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? AppColor.primaryExtraSoft : AppColor.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColor.primary : AppColor.borderStrong,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              Positioned(
                top: -4,
                right: -4,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColor.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: PhosphorIcon(PhosphorIconsBold.check, color: Colors.white, size: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
      icon: PhosphorIconsDuotone.currencyCircleDollar,
      title: 'Which currency\ndo you use?',
      subtitle: 'Every amount, budget and goal will use it.',
      child: Obx(() {
        final selected = ctrl.currency.value;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.35,
          ),
          itemCount: _currencies.length,
          itemBuilder: (_, i) {
            final (code, symbol, name, flag) = _currencies[i];
            final isSelected = selected == code;
            return _OptionTile(
              selected: isSelected,
              onTap: () => ctrl.selectCurrency(code, symbol),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColor.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(flag, style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$symbol  $code',
                          style: GoogleFonts.urbanist(
                            color: AppColor.textPrimary,
                            fontSize: 14,
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
                ],
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
    ('Salaried Employee', PhosphorIconsDuotone.briefcase),
    ('Self-employed', PhosphorIconsDuotone.buildings),
    ('Freelancer', PhosphorIconsDuotone.laptop),
    ('Student', PhosphorIconsDuotone.graduationCap),
    ('Business Owner', PhosphorIconsDuotone.storefront),
    ('Homemaker', PhosphorIconsDuotone.house),
    ('Retired', PhosphorIconsDuotone.sunHorizon),
    ('Other', PhosphorIconsDuotone.dotsThreeCircle),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();

    return _StepScaffold(
      icon: PhosphorIconsDuotone.userCircle,
      title: 'What do you\ndo for a living?',
      subtitle: 'So budget tips fit how you actually earn.',
      child: Obx(() {
        final selected = ctrl.occupation.value;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          itemCount: _occupations.length,
          itemBuilder: (_, i) {
            final (label, icon) = _occupations[i];
            final isSelected = selected == label;
            return _OptionTile(
              selected: isSelected,
              onTap: () => ctrl.selectOccupation(label),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColor.primary.withValues(alpha: 0.12)
                          : AppColor.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: PhosphorIcon(icon,
                          size: 20,
                          color: isSelected ? AppColor.primary : AppColor.textSecondary,
                          duotoneSecondaryOpacity: 0.3),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.urbanist(
                      color: AppColor.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

// ── Step 3 — Monthly budget ───────────────────────────────────────────────────

class _BudgetStep extends StatelessWidget {
  const _BudgetStep();

  static const _quickAmounts = [
    '10,000', '20,000', '30,000',
    '50,000', '75,000', '1,00,000',
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();

    return _StepScaffold(
      icon: PhosphorIconsDuotone.shieldCheck,
      title: 'Set a monthly\nspending budget',
      subtitle: 'A rough number is fine — you can change it anytime.',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        children: [
          _BudgetField(ctrl: ctrl),
          const SizedBox(height: 18),
          Text('Popular picks', style: AppTypography.captionSemiBold(AppColor.textTertiary)),
          const SizedBox(height: 10),
          Obx(() {
            final current = ctrl.budgetText.value;
            final sym = ctrl.currencySymbol.value;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amt) {
                final isSelected = current == amt;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ctrl.budgetController.text = amt;
                    ctrl.budgetController.selection =
                        TextSelection.collapsed(offset: amt.length);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColor.primary : AppColor.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? AppColor.primary : AppColor.borderStrong,
                      ),
                    ),
                    child: Text(
                      '$sym$amt',
                      style: GoogleFonts.urbanist(
                        color: isSelected ? Colors.white : AppColor.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColor.bannerBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const PhosphorIcon(PhosphorIconsDuotone.bellRinging,
                    size: 22, color: AppColor.primary, duotoneSecondaryOpacity: 0.3),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We\'ll nudge you at 80% and show how much you can safely spend each day.',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: AppColor.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _focused ? AppColor.primary : AppColor.borderStrong,
            width: _focused ? 1.6 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColor.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Obx(() => Text(
                  widget.ctrl.currencySymbol.value,
                  style: GoogleFonts.urbanist(
                    color: _focused ? AppColor.primary : AppColor.textTertiary,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                )),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.ctrl.budgetController,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.urbanist(
                  color: AppColor.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.urbanist(
                    color: AppColor.textTertiary.withValues(alpha: 0.6),
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
              ),
            ),
            Text('/ month', style: AppTypography.caption(AppColor.textTertiary)),
          ],
        ),
      );
}

// ── Step 4 — Categories ───────────────────────────────────────────────────────

class _CatItem {
  final String label;
  final Object icon;
  const _CatItem(this.label, this.icon);
}

class _CategoriesStep extends StatelessWidget {
  const _CategoriesStep();

  static const _cats = [
    _CatItem('Food & Drinks', PhosphorIconsDuotone.forkKnife),
    _CatItem('Groceries', PhosphorIconsDuotone.shoppingCart),
    _CatItem('Transport', PhosphorIconsDuotone.bus),
    _CatItem('Bills & Fees', PhosphorIconsDuotone.receipt),
    _CatItem('Health', PhosphorIconsDuotone.heartbeat),
    _CatItem('Car', PhosphorIconsDuotone.car),
    _CatItem('Shopping', PhosphorIconsDuotone.shoppingBag),
    _CatItem('Entertainment', PhosphorIconsDuotone.popcorn),
    _CatItem('Investments', PhosphorIconsDuotone.trendUp),
    _CatItem('Education', PhosphorIconsDuotone.graduationCap),
    _CatItem('Travel', PhosphorIconsDuotone.airplaneTilt),
    _CatItem('Gifts', PhosphorIconsDuotone.gift),
    _CatItem('Subscriptions', PhosphorIconsDuotone.repeat),
    _CatItem('Others', PhosphorIconsDuotone.squaresFour),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();

    return _StepScaffold(
      icon: PhosphorIconsDuotone.squaresFour,
      title: 'Where does your\nmoney usually go?',
      subtitle: 'Pick a few — they\'ll show up first when you log.',
      child: Obx(() {
        final selected = ctrl.selectedCategories.toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _cats.map((cat) {
                final isSelected = selected.contains(cat.label);
                final color = AppColor.categoryColor(cat.label);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ctrl.toggleCategory(cat.label);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColor.primaryExtraSoft : AppColor.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? AppColor.primary : AppColor.borderStrong,
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColor.primary : color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isSelected
                                ? const PhosphorIcon(PhosphorIconsBold.check,
                                    size: 14, color: Colors.white)
                                : PhosphorIcon(cat.icon,
                                    size: 16, color: color, duotoneSecondaryOpacity: 0.3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat.label,
                          style: GoogleFonts.urbanist(
                            color: AppColor.textPrimary,
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                selected.isEmpty
                    ? 'Tip: pick at least 3 for a quicker logging screen.'
                    : '${selected.length} selected',
                key: ValueKey(selected.length),
                style: AppTypography.captionSemiBold(
                    selected.isEmpty ? AppColor.textTertiary : AppColor.primary),
              ),
            ),
          ],
        );
      }),
    );
  }
}
