import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/main.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_pages.dart';

class HomeController extends GetxController {
  var userEmail = ''.obs;
  var userName = ''.obs;
  var imageUrl = ''.obs;

  @override
  void onInit() async {
    super.onInit();
    await getProfile();
  }

  Future<void> getProfile() async {
    final prefs = await SharedPreferences.getInstance();

    List<dynamic> res = await supabaseC
        .from("Users")
        .select()
        .match({"email": supabaseC.auth.currentUser!.email});

    if (res.isNotEmpty) {
      Map<String, dynamic> user = res.first as Map<String, dynamic>;
      // Save user's email and name in shared preferences
      await prefs.setString('name', user['name']);
      await prefs.setString('email', user['email']);

      // Update reactive variables
      userEmail.value = user['email'];
      userName.value = user['name'];
    } else {
      // Handle case when no user is found
      CustomToast.errorToast("Error", 'User not found');
      // You may want to navigate the user to a specific screen or handle this case differently
    }
  }

  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await supabaseC.auth.signOut();
    prefs.clear();
    Get.offAllNamed(Routes.SPLASH);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      await supabaseC.auth.signOut();
      CustomToast.successToast("Success", "Signed out successfully");
    } on AuthException catch (error) {
      CustomToast.errorToast("Error", error.message);
    } catch (error) {
      CustomToast.errorToast("Error", 'Unexpected error occurred');
    } finally {
      prefs.clear();
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}
