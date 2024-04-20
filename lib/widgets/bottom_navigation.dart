
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:spendify/view/home/home_screen.dart';
import 'package:spendify/view/wallet/wallet_screen.dart';

var hideBottomAppBarController = ScrollController();

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav>
    with SingleTickerProviderStateMixin {
  var _isVisible;
  int index_x = 0;

  var initialIndex = 0;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _isVisible = true;

    // Initialize the ScrollController
    hideBottomAppBarController = ScrollController();

    // Add a listener to the ScrollController
    hideBottomAppBarController.addListener(() {
      // Determine the scroll direction
      final ScrollDirection direction =
          hideBottomAppBarController.position.userScrollDirection;

      // Show the bottom navigation bar when scrolling in reverse
      if (direction == ScrollDirection.reverse) {
        setState(() {
          _isVisible = true;
        });
      }
      // Hide the bottom navigation bar when scrolling forward
      else if (direction == ScrollDirection.forward) {
        setState(() {
          _isVisible = false;
        });
      } else {
        _isVisible = true;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _tabController?.dispose();
  }

  final screens = [
    const HomeScreen(),
    const WalletScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      index_x = index;
    });
  }

  //floating bottom nav bar
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        body: TabBarView(
          clipBehavior: Clip.none,
          physics: const NeverScrollableScrollPhysics(),
          controller: _tabController,
          children: const [
            HomeScreen(),
            // SearchScreen(),
            WalletScreen(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isVisible ? 70.0 : 0.0,
          child: Visibility(
            visible: _isVisible,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.blueGrey,
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.home_rounded, size: 30)),
                    Tab(icon: Icon(Icons.wallet, size: 30)),
                  ],
                  unselectedLabelColor: Colors.black38,
                  labelColor: Colors.white,
                  indicatorColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//previous bottom nav bar
  // @override
  // Widget build(BuildContext context) {
  //   Size size = MediaQuery.of(context).size;
  //   return SafeArea(
  //     child: Scaffold(
  //       body: screens[index_x],
  //       bottomNavigationBar: Container(
  //         color: Colors.black12,
  //         child: Padding(
  //           padding: const EdgeInsets.all(20.0),
  //           child: Container(
  //             height: 70,
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(30),
  //               child: BottomNavigationBar(
  //                 elevation: 10.0,
  //                 backgroundColor: Color(0xFF4051A9),
  //                 items: <BottomNavigationBarItem>[
  //                   BottomNavigationBarItem(
  //                     icon: Icon(Icons.home_rounded),
  //                     label: 'Home',
  //                   ),
  //                   BottomNavigationBarItem(
  //                     icon: Icon(Icons.wallet),
  //                     label: 'Wallet',
  //                   ),
  //                 ],
  //                 type: BottomNavigationBarType.fixed,
  //                 currentIndex: index_x,
  //                 selectedItemColor: Colors.white,
  //                 unselectedItemColor: Colors.black.withOpacity(0.5),
  //                 selectedLabelStyle: const TextStyle(
  //                   color: Colors.black,
  //                   fontFamily: 'Roboto',
  //                   fontWeight: FontWeight.w200,
  //                   fontSize: 14,
  //                 ),
  //                 unselectedLabelStyle: TextStyle(
  //                   color: Colors.amber,
  //                   fontSize: 12,
  //                 ),
  //                 iconSize: 30,
  //                 onTap: _onItemTapped,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
