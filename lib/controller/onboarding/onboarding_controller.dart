// ignore_for_file: avoid_print
//
// Supabase SQL — run once in the SQL editor:
// ─────────────────────────────────────────────────────────────────────────────
// CREATE TABLE IF NOT EXISTS user_profiles (
//   user_id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
//   currency        TEXT NOT NULL DEFAULT 'INR',
//   currency_symbol TEXT NOT NULL DEFAULT '₹',
//   occupation      TEXT NOT NULL DEFAULT '',
//   monthly_budget  NUMERIC(12,2) NOT NULL DEFAULT 0,
//   selected_categories TEXT[] NOT NULL DEFAULT '{}',
//   onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE,
//   created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
// );
//
// ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
//
// CREATE POLICY "Users manage own profile"
//   ON user_profiles FOR ALL
//   USING  (auth.uid() = user_id)
//   WITH CHECK (auth.uid() = user_id);
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendify/main.dart';
import 'package:spendify/routes/app_pages.dart';
import 'package:spendify/widgets/bottom_navigation.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();

  final RxInt currentStep = 0.obs;
  static const int totalSteps = 4;

  // Step 1 — Currency
  final RxString currency = 'INR'.obs;
  final RxString currencySymbol = '₹'.obs;

  // Step 2 — Occupation
  final RxString occupation = ''.obs;

  // Step 3 — Monthly budget
  final RxDouble monthlyBudget = 0.0.obs;
  final TextEditingController budgetController = TextEditingController();

  // Step 4 — Categories
  final RxList<String> selectedCategories = <String>[].obs;

  final RxBool isSaving = false.obs;

  @override
  void onClose() {
    pageController.dispose();
    budgetController.dispose();
    super.onClose();
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

  void nextStep() {
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
      pageController.animateToPage(
        currentStep.value,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.animateToPage(
        currentStep.value,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _save() async {
    isSaving.value = true;
    try {
      final userId = supabaseC.auth.currentUser?.id;
      if (userId == null) {
        Get.offAllNamed(Routes.LOGIN);
        return;
      }

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

      Get.offAll(() => const BottomNav());
    } catch (e) {
      debugPrint('Onboarding save error: $e');
      CustomToast.errorToast('Error', 'Could not save preferences. Try again.');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> skip() async {
    isSaving.value = true;
    try {
      final userId = supabaseC.auth.currentUser?.id;
      if (userId == null) {
        Get.offAllNamed(Routes.LOGIN);
        return;
      }
      await supabaseC.from('user_profiles').upsert({
        'user_id': userId,
        'currency': currency.value,
        'currency_symbol': currencySymbol.value,
        'occupation': occupation.value,
        'monthly_budget': 0.0,
        'selected_categories': <String>[],
        'onboarding_complete': true,
      });
      Get.offAll(() => const BottomNav());
    } catch (e) {
      debugPrint('Onboarding skip error: $e');
      Get.offAll(() => const BottomNav());
    } finally {
      isSaving.value = false;
    }
  }

}
