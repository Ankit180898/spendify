import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
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
      await googleSignIn.signOut(); // clear cached account so picker always shows
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
    final user = supabaseC.auth.currentUser;
    if (user == null) return;
    final userId = user.id;

    // Ensure user row exists in public.users (stores name, email, balance).
    // ignoreDuplicates keeps existing balance untouched for returning users.
    try {
      await supabaseC.from('users').upsert(
        {
          'id': userId,
          'email': user.email ?? '',
          'name': user.userMetadata?['full_name'] ??
              user.userMetadata?['name'] ??
              '',
          'balance': 0,
          'url': user.userMetadata?['avatar_url'] ?? '',
        },
        onConflict: 'id',
        ignoreDuplicates: true,
      );
    } catch (e) {
      debugPrint('LoginController: users upsert failed — $e');
    }

    try {
      final profile = await supabaseC
          .from('user_profiles')
          .select('onboarding_complete')
          .eq('user_id', userId)
          .maybeSingle();
      if (profile != null && profile['onboarding_complete'] == true) {
        Get.offAll(const BottomNav());
      } else {
        // No profile row = new user
        final email = user.email ?? '';
        final name = user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            '';
        if (email.isNotEmpty) {
          await _sendWelcomeEmail(email: email, name: name);
        }
        Get.offAllNamed(Routes.ONBOARDING);
      }
    } catch (e) {
      debugPrint('LoginController: _navigateAfterAuth failed — $e');
      Get.offAllNamed(Routes.ONBOARDING);
    }
  }

  Future<void> _sendWelcomeEmail({
    required String email,
    required String name,
  }) async {
    try {
      final apiKey = dotenv.env['BREVO_API_KEY'] ?? '';
      if (apiKey.isEmpty || apiKey == 'your_brevo_api_key_here') return;

      final headers = {
        'accept': 'application/json',
        'api-key': apiKey,
        'content-type': 'application/json',
      };

      // Create contact in Brevo
      final contactRes = await http.post(
        Uri.parse('https://api.brevo.com/v3/contacts'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'attributes': {'FIRSTNAME': name},
          'updateEnabled': true,
        }),
      );
      debugPrint('Brevo contact: ${contactRes.statusCode} ${contactRes.body}');

      // Send welcome email
      final emailRes = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: headers,
        body: jsonEncode({
          'sender': {'name': 'Spendify', 'email': 'ankit.me180898@gmail.com'},
          'to': [
            {'email': email, 'name': name.isNotEmpty ? name : email}
          ],
          'subject': 'Welcome to Spendify!',
          'htmlContent': '''
            <h2>Hey ${name.isNotEmpty ? name : 'there'}, welcome to Spendify!</h2>
            <p>You're all set to start tracking your expenses smarter.</p>
            <ul>
              <li>Log your daily expenses</li>
              <li>Set savings goals</li>
              <li>Split bills with friends</li>
            </ul>
            <p>Happy spending (wisely)!</p>
          ''',
        }),
      );
      debugPrint('Brevo email: ${emailRes.statusCode} ${emailRes.body}');
    } catch (e) {
      debugPrint('LoginController: welcome email failed — $e');
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
