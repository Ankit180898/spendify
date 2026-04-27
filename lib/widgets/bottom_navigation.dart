import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/groups_controller/groups_controller.dart';
import 'package:spendify/controller/health_score_controller/health_score_controller.dart';
import 'package:spendify/controller/savings_controller/savings_controller.dart';
import 'package:spendify/controller/recurring_bills_controller/recurring_bills_controller.dart';
import 'package:spendify/controller/upi_capture_controller/upi_capture_controller.dart';
import 'package:spendify/controller/walkthrough_controller.dart';
import 'package:spendify/view/goals/goals_screen.dart';
import 'package:spendify/view/home/home_screen.dart';
import 'package:spendify/view/profile/profile_screen.dart';
import 'package:spendify/view/splits/splits_screen.dart';
import 'package:spendify/view/wallet/statistics_screen.dart';
import 'package:spendify/view/upi_capture/upi_permission_screen.dart';
import 'package:spendify/view/wallet/add_transaction_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _current = 0;
  bool _showcaseTriggered = false;
  bool _dialOpen = false;
  bool _dialVisible = false;

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
    if (!Get.isRegistered<HealthScoreController>()) Get.put(HealthScoreController());
    if (!Get.isRegistered<GroupsController>()) Get.put(GroupsController(), permanent: true);
    if (!Get.isRegistered<WalkthroughController>()) Get.put(WalkthroughController());
    if (!Get.isRegistered<RecurringBillsController>()) {
      Get.put(RecurringBillsController(), permanent: true);
    }
    if (Platform.isAndroid) {
      if (!Get.isRegistered<UpiCaptureController>()) Get.put(UpiCaptureController(), permanent: true);
    }
  }

  void _toggleDial(BuildContext context) {
    HapticFeedback.mediumImpact();
    if (_current == 2) {
      if (_dialOpen) _closeDial();
      showGoalsAddPicker(context);
      return;
    }
    if (_dialOpen) {
      _closeDial();
      return;
    }
    setState(() {
      _dialVisible = true;
      _dialOpen = true;
    });
  }

  void _closeDial() {
    if (!_dialVisible) return;
    setState(() => _dialOpen = false);
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (_dialOpen) return; // reopened
      setState(() => _dialVisible = false);
    });
  }

  void _addExpense() {
    _closeDial();
    Get.to(() => const AddTransactionScreen(initialType: 'expense'));
  }

  void _addIncome() {
    _closeDial();
    Get.to(() => const AddTransactionScreen(initialType: 'income'));
  }

  void _addSplitBill() {
    _closeDial();
    // Splits is not a bottom-tab destination; open it as a flow.
    Get.to(() => const SplitsScreen(), transition: Transition.cupertino);
  }

  Future<void> _maybeShowUpiPermission() async {
    if (!Platform.isAndroid) return;
    if (!Get.isRegistered<UpiCaptureController>()) return;
    final ctrl = Get.find<UpiCaptureController>();
    final should = await ctrl.shouldPromptPermission();
    if (!should) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Get.to(() => const UpiPermissionScreen(), transition: Transition.cupertino);
  }

  void _maybeStartShowcase(BuildContext ctx) {
    if (_showcaseTriggered) return;
    _showcaseTriggered = true;
    // Capture showcase state before the async gap to avoid stale context
    final showcaseState = ShowCaseWidget.of(ctx);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctrl = Get.find<WalkthroughController>();
      if (await ctrl.shouldShow()) {
        if (mounted) showcaseState.startShowCase(ctrl.orderedKeys);
        ctrl.markShown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShowCaseWidget(
      blurValue: 2,
      onFinish: () => _maybeShowUpiPermission(),
      builder: (showcaseCtx) {
        _maybeStartShowcase(showcaseCtx);
        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              GestureDetector(
                onTap: _closeDial,
                behavior: HitTestBehavior.translucent,
                child: IndexedStack(index: _current, children: _screens),
              ),
              if (_dialVisible)
                Positioned.fill(
                  child: _AddSpeedDial(
                    isDark: isDark,
                    open: _dialOpen,
                    onClose: _closeDial,
                    onExpense: _addExpense,
                    onIncome: _addIncome,
                    onSplitBill: _addSplitBill,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _NavBar(
            current: _current,
            isDark: isDark,
            onTap: (i) {
              _closeDial();
              setState(() => _current = i);
            },
            onAdd: () => _toggleDial(context),
            dialOpen: _dialOpen,
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
  final bool dialOpen;

  const _NavBar({
    required this.current,
    required this.isDark,
    required this.onTap,
    required this.onAdd,
    required this.dialOpen,
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        shape: BoxShape.circle,
                        boxShadow: dialOpen
                            ? [
                                BoxShadow(
                                  color: AppColor.primary.withValues(alpha: 0.55),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 220),
                        turns: dialOpen ? 0.125 : 0.0, // 45°
                        child: const PhosphorIcon(
                          PhosphorIconsLight.plus,
                          color: Colors.white,
                          size: 22,
                        ),
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

// ── Add speed dial overlay ────────────────────────────────────────────────────

class _AddSpeedDial extends StatelessWidget {
  final bool isDark;
  final bool open;
  final VoidCallback onClose;
  final VoidCallback onExpense;
  final VoidCallback onSplitBill;
  final VoidCallback onIncome;

  const _AddSpeedDial({
    required this.isDark,
    required this.open,
    required this.onClose,
    required this.onExpense,
    required this.onSplitBill,
    required this.onIncome,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final scrim = Colors.black.withValues(alpha: isDark ? 0.60 : 0.40);

    // Anchor close to the centre + button (which sits inside the nav bar)
    final baseBottom = bottomPad + 18;

    return Stack(
      children: [
        // Tap-to-dismiss scrim with backdrop blur
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: open ? 1.0 : 0.0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: scrim),
            ),
          ),
        ),

        // Actions (radial arc)
        Positioned(
          left: 0,
          right: 0,
          bottom: baseBottom,
          child: SizedBox(
            height: AppDimens.navBarHeight + 170,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                _RadialSlot(
                  open: open,
                  delayMs: 0,
                  dx: -92,
                  dy: -64,
                  child: _DialAction(
                    icon: PhosphorIconsLight.receipt,
                    label: 'Expense',
                    color: AppColor.expense,
                    onTap: onExpense,
                  ),
                ),
                _RadialSlot(
                  open: open,
                  delayMs: 40,
                  dx: 0,
                  dy: -118,
                  child: _DialAction(
                    icon: PhosphorIconsLight.usersThree,
                    label: 'Split bill',
                    color: AppColor.primary,
                    onTap: onSplitBill,
                  ),
                ),
                _RadialSlot(
                  open: open,
                  delayMs: 80,
                  dx: 92,
                  dy: -64,
                  child: _DialAction(
                    icon: PhosphorIconsLight.money,
                    label: 'Income',
                    color: AppColor.income,
                    onTap: onIncome,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RadialSlot extends StatefulWidget {
  final bool open;
  final int delayMs;
  final double dx;
  final double dy;
  final Widget child;

  const _RadialSlot({
    required this.open,
    required this.delayMs,
    required this.dx,
    required this.dy,
    required this.child,
  });

  @override
  State<_RadialSlot> createState() => _RadialSlotState();
}

class _RadialSlotState extends State<_RadialSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    if (widget.open) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void didUpdateWidget(_RadialSlot old) {
    super.didUpdateWidget(old);
    if (widget.open == old.open) return;
    if (widget.open) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        return Transform.translate(
          offset: Offset(widget.dx * t, widget.dy * t),
          child: Transform.scale(
            scale: 0.65 + 0.35 * t,
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _DialAction extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: PhosphorIcon(icon, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
