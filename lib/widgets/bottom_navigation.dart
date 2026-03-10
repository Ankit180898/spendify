import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';
import 'package:spendify/controller/goals_controller/goals_controller.dart';
import 'package:spendify/controller/savings_controller/savings_controller.dart';
import 'package:spendify/view/goals/goals_screen.dart';
import 'package:spendify/view/home/home_screen.dart';
import 'package:spendify/view/profile/profile_screen.dart';
import 'package:spendify/view/wallet/statistics_screen.dart';
import 'package:spendify/widgets/common_bottom_sheet.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _current = 0;

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
  }

  void _openAddSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CommonBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              // Stats
              Expanded(
                child: _NavItem(
                  icon: PhosphorIconsLight.chartBar,
                  label: 'Stats',
                  isActive: current == 1,
                  onTap: () => onTap(1),
                ),
              ),
              // ── Centre + button ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spaceLG, vertical: AppDimens.spaceSM),
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColor.primaryGradient,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                      boxShadow: AppShadows.primaryStrong,
                    ),
                    child: const PhosphorIcon(
                      PhosphorIconsRegular.plus,
                      color: Colors.white,
                      size: AppDimens.iconXL,
                    ),
                  ),
                ),
              ),
              // Goals
              Expanded(
                child: _NavItem(
                  icon: PhosphorIconsLight.wallet,
                  label: 'Goals',
                  isActive: current == 2,
                  onTap: () => onTap(2),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spaceMD, vertical: AppDimens.spaceXS),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColor.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
            ),
            child: PhosphorIcon(icon, color: color, size: AppDimens.iconLG),
          ),
          const SizedBox(height: AppDimens.spaceXXS),
          Text(label, style: AppTypography.label(color)),
        ],
      ),
    );
  }
}
