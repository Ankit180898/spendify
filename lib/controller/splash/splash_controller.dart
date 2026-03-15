import 'dart:async';
import 'package:get/get.dart';
import 'package:spendify/main.dart';
import 'package:spendify/routes/app_pages.dart';
import 'package:spendify/widgets/bottom_navigation.dart';

class SplashController extends GetxController {
  Timer? _splashTimer;

  @override
  void onInit() {
    super.onInit();
    _splashTimer = Timer(const Duration(seconds: 2), () => _checkAuthentication());
  }

  @override
  void onClose() {
    _splashTimer?.cancel();
    super.onClose();
  }

  Future<void> _checkAuthentication() async {
    final session = supabaseC.auth.currentSession;

    if (session != null) {
      try {
        final profile = await supabaseC
            .from('user_profiles')
            .select('onboarding_complete')
            .eq('user_id', session.user.id)
            .maybeSingle();

        if (profile != null && profile['onboarding_complete'] == true) {
          Get.offAll(const BottomNav());
        } else {
          Get.offAllNamed(Routes.ONBOARDING);
        }
      } catch (_) {
        // Offline or table error — user is logged in so go home, not onboarding
        Get.offAll(const BottomNav());
      }
    } else {
      Get.offAllNamed(Routes.GETSTARTED);
    }
  }
}
