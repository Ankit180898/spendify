import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/transaction_model.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_pages.dart';
import '../../widgets/transaction_graph.dart';

class HomeController extends GetxController {
  var userEmail = ''.obs;
  var userName = ''.obs;
  var totalBalance = 0.obs;
  var imageUrl = ''.obs;
  var transactions = <Map<String, dynamic>>[].obs;
    var transactionsList = <TransactionModel>[].obs; // Adjust the type here

  var isLoading = false.obs;

  @override
  void onInit() async {
    super.onInit();
    await getProfile();
    await getTransactions();
  }

  Future<void> getProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final user = supabaseC.auth.currentUser;
    if (user != null) {
      final response = await supabaseC.from("users").select().eq('id', user.id);

      if (response.isEmpty) {
        // Handle error
        CustomToast.errorToast("Error", 'Error fetching user profile');
        return;
      }

      final userData = response.first;
      // Save user's email, name, and balance in shared preferences
      await prefs.setString('name', userData['name']);
      await prefs.setString('email', userData['email']);

      // Update reactive variables
      userEmail.value = userData['email'];
      userName.value = userData['name'];
      totalBalance.value = userData['balance'] ?? 0.0;
    } else {
      // Handle case when no user is found
      CustomToast.errorToast("Error", 'User not found');
      // You may want to navigate the user to a specific screen or handle this case differently
    }
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

  Future<void> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();

    isLoading.value = true;
    transactions.value = await supabaseC
        .from("transactions")
        .select()
        .eq('user_id', supabaseC.auth.currentUser!.id);

        
    isLoading.value = false;
  }

  

  
}
