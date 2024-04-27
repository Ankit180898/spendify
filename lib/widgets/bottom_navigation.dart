import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax/iconsax.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/utils/image_constants.dart';
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
          _isVisible = false;
        });
      }
      // Hide the bottom navigation bar when scrolling forward
      else if (direction == ScrollDirection.forward) {
        setState(() {
          _isVisible = true;
        });
      } else {
        setState(() {
          _isVisible = false;
        });
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
    const NewWalletScreen(),
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
            //WalletScreen()
            NewWalletScreen(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Stack(
          fit: StackFit.loose,
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _isVisible ? displayHeight(context) * 0.10 : 0.0,
              child: Visibility(
                visible: _isVisible,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: displayHeight(context) * 0.20,
                    width: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(40),
                      gradient: SweepGradient(
                          colors: [AppColor.primarySoft, Colors.white],
                          endAngle: 20,
                          startAngle: 10),
                    ),
                    child: TabBar(
                      automaticIndicatorColorAdjustment: false,
                      dividerColor: Colors.transparent,
                      controller: _tabController,
                      tabs: const [
                        Tab(
                            icon: Icon(
                          Iconsax.home,
                          size: 30,
                        )),
                        Tab(
                            icon: Icon(
                          Iconsax.wallet,
                          size: 30,
                        )),
                      ],
                      unselectedLabelColor: AppColor.secondarySoft,
                      labelColor: Colors.white,
                      indicatorColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
            // Place the SpeedDial on top
            Visibility(
              visible: _isVisible,
              child: Positioned(
                  bottom: displayHeight(context) * 0.05, // Adjust as needed
                  right:
                      displayWidth(context) / 2 - 50 - 70, // Adjust as needed
                  child: FloatingActionButton(
                    onPressed: () {
                      showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          builder: (context) => const BottomSheetExample());
                    },
                    backgroundColor: AppColor.secondary,
                    shape: const CircleBorder(),
                    child: ImageConstants(colors: Colors.white).plus,
                  )),
            ),
          ],
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
