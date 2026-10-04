import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/model/weekly_digest_model.dart';
import 'package:spendify/services/weekly_digest_service.dart';

class WeeklyDigestController extends GetxController {
  var digest = Rxn<WeeklyDigest>();
  var isBannerDismissed = false.obs;

  static const _prefKey = 'dismissed_digest_week';

  @override
  void onInit() {
    super.onInit();
    _loadDismissState();
    Future.delayed(Duration.zero, _setupAndCompute);
  }

  void _setupAndCompute() {
    try {
      final homeC = Get.find<HomeController>();
      debounce(
        homeC.allTransactions,
        (_) => compute(),
        time: const Duration(milliseconds: 600),
      );
      compute();
    } catch (_) {
      Future.delayed(const Duration(milliseconds: 300), _setupAndCompute);
    }
  }

  void compute() {
    try {
      final homeC = Get.find<HomeController>();
      digest.value = WeeklyDigestService.compute(
        allTransactions: homeC.allTransactions.toList(),
        monthlyBudget: homeC.monthlyBudget.value,
        sym: homeC.currencySymbol.value,
      );
    } catch (e) {
      debugPrint('WeeklyDigestController.compute error: $e');
    }
  }

  /// True only if digest exists, not dismissed, and we're Mon–Thu
  /// (4-day visibility window after the digest week ends on Sunday).
  bool get shouldShowBanner {
    if (digest.value == null || isBannerDismissed.value) return false;
    return DateTime.now().weekday <= 4;
  }

  void dismissBanner() {
    isBannerDismissed.value = true;
    _saveDismissState();
  }

  Future<void> _loadDismissState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_prefKey) ?? -1;
      final now = DateTime.now();
      final thisMon = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      isBannerDismissed.value = saved == WeeklyDigestService.weekNumber(thisMon);
    } catch (e) {
      debugPrint('WeeklyDigestController._loadDismissState error: $e');
    }
  }

  Future<void> _saveDismissState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final thisMon = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      await prefs.setInt(_prefKey, WeeklyDigestService.weekNumber(thisMon));
    } catch (e) {
      debugPrint('WeeklyDigestController._saveDismissState error: $e');
    }
  }
}
