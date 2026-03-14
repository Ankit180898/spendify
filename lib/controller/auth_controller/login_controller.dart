import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:spendify/main.dart';
import 'package:spendify/routes/app_pages.dart';
import 'package:spendify/widgets/bottom_navigation.dart';

import 'package:spendify/widgets/toast/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController extends GetxController {
  RxBool isGoogleLoading = false.obs;
  RxBool isAppleLoading = false.obs;

  Future<void> signInWithGoogle() async {
    isGoogleLoading.value = true;
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '1022798183394-tq8i6uqjn86e4l6df8ebp7pudgrefb18.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        isGoogleLoading.value = false;
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) throw Exception('No ID token from Google');

      await supabaseC.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      isGoogleLoading.value = false;
      await _navigateAfterAuth();
    } catch (e) {
      isGoogleLoading.value = false;
      CustomToast.errorToast('Sign-in failed', e.toString());
    }
  }

  Future<void> signInWithApple() async {
    isAppleLoading.value = true;
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) throw Exception('No identity token from Apple');

      await supabaseC.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      isAppleLoading.value = false;
      await _navigateAfterAuth();
    } catch (e) {
      isAppleLoading.value = false;
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        return;
      }
      CustomToast.errorToast('Sign-in failed', e.toString());
    }
  }

  Future<void> _navigateAfterAuth() async {
    final userId = supabaseC.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final profile = await supabaseC
          .from('user_profiles')
          .select('onboarding_complete')
          .eq('user_id', userId)
          .maybeSingle();
      if (profile != null && profile['onboarding_complete'] == true) {
        Get.offAll(const BottomNav());
      } else {
        Get.offAllNamed(Routes.ONBOARDING);
      }
    } catch (_) {
      Get.offAllNamed(Routes.ONBOARDING);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
