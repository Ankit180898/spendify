import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/savings_controller/savings_controller.dart';
import 'package:spendify/controller/walkthrough_controller.dart';
import 'package:spendify/view/goals/goals_screen.dart';
import 'package:spendify/view/home/home_screen.dart';
import 'package:spendify/view/profile/profile_screen.dart';
import 'package:spendify/view/wallet/statistics_screen.dart';
import 'package:spendify/view/wallet/add_transaction_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _current = 0;
  bool _showcaseTriggered = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    StatisticsScreen(),
    GoalsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<GoalsController>()) Get.put(GoalsController());
    if (!Get.isRegistered<SavingsController>()) Get.put(SavingsController());
    if (!Get.isRegistered<WalkthroughController>()) {
      Get.put(WalkthroughController());
    }
  }

  void _openAddSheet() {
    HapticFeedback.mediumImpact();
    Get.to(() => const AddTransactionScreen());
  }

  void _maybeStartShowcase(BuildContext ctx) {
    if (_showcaseTriggered) return;
    _showcaseTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctrl = Get.find<WalkthroughController>();
      if (await ctrl.shouldShow()) {
        ShowCaseWidget.of(ctx).startShowCase(ctrl.orderedKeys);
        ctrl.markShown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShowCaseWidget(
      blurValue: 2,
      onFinish: () {},
      builder: (showcaseCtx) {
        _maybeStartShowcase(showcaseCtx);
        return Scaffold(
          extendBody: true,
          body: IndexedStack(index: _current, children: _screens),
          bottomNavigationBar: _NavBar(
            current: _current,
            isDark: isDark,
            onTap: (i) => setState(() => _current = i),
            onAdd: _openAddSheet,
          ),
        );
      },
    );
  }
}

// ── Nav bar ───────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int current;
  final bool isDark;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  const _NavBar({
    required this.current,
    required this.isDark,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColor.darkSurface : AppColor.lightSurface;
    final border = isDark ? AppColor.darkBorder : AppColor.lightBorder;
    final wCtrl = Get.find<WalkthroughController>();

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimens.navBarHeight,
          child: Row(
            children: [
              // Home
              Expanded(
                child: _NavItem(
                  icon: PhosphorIconsLight.house,
                  label: 'Home',
                  isActive: current == 0,
                  onTap: () => onTap(0),
                ),
              ),
              // Stats — showcased
              Expanded(
                child: Showcase(
                  key: wCtrl.statsNavKey,
                  title: 'Smart insights',
                  description:
                      'Charts and spending breakdowns to understand where your money goes.',
                  targetShapeBorder: const CircleBorder(),
                  tooltipBackgroundColor: AppColor.primary,
                  textColor: Colors.white,
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  descTextStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  child: _NavItem(
                    icon: PhosphorIconsLight.chartBar,
                    label: 'Stats',
                    isActive: current == 1,
                    onTap: () => onTap(1),
                  ),
                ),
              ),
              // ── Centre + button — showcased ──
              Showcase(
                key: wCtrl.addBtnKey,
                title: 'Log a transaction',
                description:
                    'Tap + anytime to record an expense or income instantly.',
                targetShapeBorder: const CircleBorder(),
                tooltipBackgroundColor: AppColor.primary,
                textColor: Colors.white,
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                descTextStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.5,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spaceLG,
                      vertical: AppDimens.spaceSM),
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColor.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const PhosphorIcon(
                        PhosphorIconsLight.plus,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              // Goals — showcased
              Expanded(
                child: Showcase(
                  key: wCtrl.goalsNavKey,
                  title: 'Budgets & goals',
                  description:
                      'Set category spending limits and track your savings goals.',
                  targetShapeBorder: const CircleBorder(),
                  tooltipBackgroundColor: AppColor.primary,
                  textColor: Colors.white,
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  descTextStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  child: _NavItem(
                    icon: PhosphorIconsLight.wallet,
                    label: 'Goals',
                    isActive: current == 2,
                    onTap: () => onTap(2),
                  ),
                ),
              ),
              // Profile
              Expanded(
                child: _NavItem(
                  icon: PhosphorIconsLight.user,
                  label: 'Profile',
                  isActive: current == 3,
                  onTap: () => onTap(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColor.primary : AppColor.textTertiary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(icon, color: color, size: AppDimens.iconLG),
          const SizedBox(height: AppDimens.spaceXXS),
          Text(label, style: AppTypography.label(color)),
        ],
      ),
    );
  }
}
