import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax/iconsax.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/utils/size_helpers.dart';
import 'package:spendify/view/home/home_screen.dart';
import 'package:spendify/view/wallet/new_wallet_screen.dart';
import 'package:spendify/widgets/common_bottom_sheet.dart';

var hideBottomAppBarController = ScrollController();

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  bool _isVisible = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    hideBottomAppBarController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.dispose();
    hideBottomAppBarController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    final direction = hideBottomAppBarController.position.userScrollDirection;
    setState(() {
      _isVisible = (direction == ScrollDirection.forward);
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      currentIndex = index;
      _tabController.index = currentIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            HomeScreen(),
            NewWalletScreen(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _buildFloatingActionButton(),
        bottomNavigationBar: Material(
            color: Colors.transparent, child: _buildBottomNavigationBar()),
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
            builder: (context) => const BottomSheetExample(),
          );
        },
        backgroundColor: Colors.indigo[50],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: const Icon(Iconsax.add, size: 36),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _isVisible ? kBottomNavigationBarHeight : 0.0,
      child: Visibility(
        visible: _isVisible,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: kBottomNavigationBarHeight,
            child: TabBar(
              controller: _tabController,
              onTap: _onTabTapped,
              tabs: const [
                Tab(icon: Icon(Iconsax.home, size: 30)),
                Tab(icon: Icon(Iconsax.chart_square, size: 30)),
              ],
              unselectedLabelColor: AppColor.secondarySoft,
              labelColor: Colors.white,
              indicator: BoxDecoration(
                // This removes the default indicator line
                color: Colors.transparent,
              ),
              indicatorColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
