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
    // Initialize shared preferences

    // Get current session
    final session = supabaseC.auth.currentSession;

    if (session != null) {
      // User is authenticated 
      // Navigate to the home screen
      Get.offAll(const BottomNav());
    } else {
      // User is not authenticated

      // Navigate to the get started screen
      Get.offAllNamed(Routes.GETSTARTED);
    }
  }
}
