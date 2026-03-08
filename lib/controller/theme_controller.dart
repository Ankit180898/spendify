import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/config/app_theme.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  final _isDarkMode = true.obs;

  bool get isDarkMode => _isDarkMode.value;

  ThemeMode get themeMode =>
      _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeTheme(
      _isDarkMode.value ? AppTheme.darkTheme() : AppTheme.lightTheme(),
    );
    _saveTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = prefs.getBool('isDarkMode') ?? true;
    Get.changeTheme(
      _isDarkMode.value ? AppTheme.darkTheme() : AppTheme.lightTheme(),
    );
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode.value);
  }

  // Convenience helpers for theme-aware colours used in custom widgets.
  Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
}
