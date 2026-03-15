import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';

class ConnectivityService extends GetxService {
  final isOnline = true.obs;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _checkNow();
    _sub = Connectivity().onConnectivityChanged.listen((_) => _checkNow());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _checkNow() async {
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      _setOffline();
      return;
    }
    // Verify actual internet (connectivity_plus only checks network, not internet)
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      _setOnline(lookup.isNotEmpty);
    } catch (_) {
      _setOffline();
    }
  }

  void _setOnline(bool online) {
    final wasOffline = !isOnline.value;
    isOnline.value = online;
    if (!online) {
      _showBanner();
    } else if (wasOffline) {
      Get.closeCurrentSnackbar();
      _showReconnected();
    }
  }

  void _setOffline() => _setOnline(false);

  static void _showBanner() {
    final isDark = Get.isDarkMode;
    final bg = isDark ? AppColor.darkCard : Colors.white;
    final textColor = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final mutedColor = isDark ? AppColor.textSecondary : const Color(0xFF71717A);

    Get.closeCurrentSnackbar();
    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          const PhosphorIcon(PhosphorIconsLight.wifiX, color: AppColor.expense, size: 16),
          const SizedBox(width: 8),
          Text(
            'No internet connection',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
      messageText: Text(
        'Check your connection and try again.',
        style: TextStyle(color: mutedColor, fontSize: 12),
      ),
      backgroundColor: bg,
      colorText: textColor,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      borderRadius: 14,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      duration: const Duration(days: 1),
      isDismissible: false,
      icon: const SizedBox.shrink(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static void _showReconnected() {
    final isDark = Get.isDarkMode;
    final bg = isDark ? AppColor.darkCard : Colors.white;
    final textColor = isDark ? AppColor.textPrimary : const Color(0xFF09090B);

    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          const PhosphorIcon(PhosphorIconsLight.wifiHigh, color: AppColor.income, size: 16),
          const SizedBox(width: 8),
          Text(
            'Back online',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
      messageText: const SizedBox.shrink(),
      backgroundColor: bg,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      borderRadius: 14,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      duration: const Duration(seconds: 2),
      icon: const SizedBox.shrink(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  /// Call this before any Supabase operation to check if online.
  /// Returns true if online, shows banner + returns false if not.
  static bool requireInternet() {
    final svc = Get.find<ConnectivityService>();
    if (!svc.isOnline.value) {
      _showBanner();
      return false;
    }
    return true;
  }
}
