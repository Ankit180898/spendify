import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalkthroughController extends GetxController {
  // Keys for each showcase target (in order of presentation)
  final GlobalKey balanceKey = GlobalKey();
  final GlobalKey quickActionsKey = GlobalKey();
  final GlobalKey addBtnKey = GlobalKey();
  final GlobalKey statsNavKey = GlobalKey();
  final GlobalKey goalsNavKey = GlobalKey();

  static const _prefKey = 'walkthrough_shown_v1';

  List<GlobalKey> get orderedKeys => [
        // balanceKey,
        // quickActionsKey,
        // addBtnKey,
        // statsNavKey,
        // goalsNavKey,
        addBtnKey,
        statsNavKey,
        goalsNavKey,
      ];

  Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefKey) ?? false);
  }

  Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }
}
