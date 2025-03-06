import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/view/home/home_screen.dart';
import 'package:spendify/view/wallet/statistics_screen.dart';
import 'package:spendify/widgets/common_bottom_sheet.dart';

import '../utils/utils.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentIndex = 0;
  final bool _isVisible = true;
  final List<Widget> _screens = const [
    HomeScreen(),
    StatisticsScreen(),
  ];

  void _onNavTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: _screens,
        ), // Display the selected screen
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _buildFloatingActionButton(),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Visibility(
      visible: _isVisible,
      child: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) => const CommonBottomSheet(),
          );
        },
        backgroundColor: Colors.indigo[50],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: const Icon(
          Iconsax.add,
          size: 36,
          color: AppColor.darkCard,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: _onNavTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Iconsax.home, size: 30),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.chart_square, size: 30),
          label: 'Stats',
        ),
      ],
      selectedLabelStyle: normalText(16, AppColor.primarySoft),
      unselectedLabelStyle: normalText(12, AppColor.secondarySoft),
      selectedItemColor: Colors.white,
      unselectedItemColor: AppColor.secondarySoft,
      backgroundColor: AppColor.darkBackground, // Set background color
      elevation: 0, // Optional: remove shadow
    );
  }
}
