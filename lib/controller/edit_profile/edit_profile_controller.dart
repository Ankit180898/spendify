// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class EditProfileController extends GetxController {
  final RxString currency = 'INR'.obs;
  final RxString currencySymbol = '₹'.obs;
  final RxString occupation = ''.obs;
  final RxDouble monthlyBudget = 0.0.obs;
  final RxList<String> selectedCategories = <String>[].obs;
  final TextEditingController budgetController = TextEditingController();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  @override
  void onClose() {
    budgetController.dispose();
    super.onClose();
  }

  Future<void> _loadProfile() async {
    isLoading.value = true;
    try {
      final userId = supabaseC.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabaseC
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        currency.value = data['currency'] ?? 'INR';
        currencySymbol.value = data['currency_symbol'] ?? '₹';
        occupation.value = data['occupation'] ?? '';
        monthlyBudget.value =
            (data['monthly_budget'] as num?)?.toDouble() ?? 0.0;
        selectedCategories.value =
            List<String>.from(data['selected_categories'] ?? []);

        final budget = monthlyBudget.value;
        if (budget > 0) {
          budgetController.text = budget.toStringAsFixed(0);
        }
      }
    } catch (e) {
      debugPrint('EditProfile load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectCurrency(String c, String symbol) {
    currency.value = c;
    currencySymbol.value = symbol;
  }

  void selectOccupation(String o) => occupation.value = o;

  void toggleCategory(String cat) {
    if (selectedCategories.contains(cat)) {
      selectedCategories.remove(cat);
    } else {
      selectedCategories.add(cat);
    }
  }

  Future<void> save() async {
    isSaving.value = true;
    try {
      final userId = supabaseC.auth.currentUser?.id;
      if (userId == null) return;

      final budget = double.tryParse(
              budgetController.text.replaceAll(',', '').trim()) ??
          0.0;

      await supabaseC.from('user_profiles').upsert({
        'user_id': userId,
        'currency': currency.value,
        'currency_symbol': currencySymbol.value,
        'occupation': occupation.value,
        'monthly_budget': budget,
        'selected_categories': selectedCategories.toList(),
        'onboarding_complete': true,
      });

      // Sync preferences to HomeController so UI updates immediately
      try {
        final hc = Get.find<HomeController>();
        hc.currencySymbol.value = currencySymbol.value;
        hc.monthlyBudget.value = budget;
        hc.selectedCategories.value = selectedCategories.toList();
        hc.occupation.value = occupation.value;
      } catch (_) {}

      CustomToast.successToast('Saved', 'Preferences updated');
      Get.back();
    } catch (e) {
      debugPrint('EditProfile save error: $e');
      CustomToast.errorToast('Error', 'Could not save preferences. Try again.');
    } finally {
      isSaving.value = false;
    }
  }
}
