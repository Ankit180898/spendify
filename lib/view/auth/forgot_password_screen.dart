import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/main.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      CustomToast.errorToast('Invalid email', 'Please enter a valid email address');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabaseC.auth.resetPasswordForEmail(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      CustomToast.errorToast('Error', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final inputBg = isDark ? AppColor.darkCard : const Color(0xFFF4F4F5);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: PhosphorIcon(PhosphorIconsLight.arrowLeft, color: textPrimary, size: 22),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _sent ? _SuccessView(email: _emailCtrl.text.trim(), textPrimary: textPrimary, textMuted: textMuted) : _FormView(
              emailCtrl: _emailCtrl,
              isLoading: _isLoading,
              onSubmit: _sendReset,
              textPrimary: textPrimary,
              textMuted: textMuted,
              inputBg: inputBg,
              border: border,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;
  final Color textPrimary;
  final Color textMuted;
  final Color inputBg;
  final Color border;
  final bool isDark;

  const _FormView({
    required this.emailCtrl,
    required this.isLoading,
    required this.onSubmit,
    required this.textPrimary,
    required this.textMuted,
    required this.inputBg,
    required this.border,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColor.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Center(child: PhosphorIcon(PhosphorIconsLight.key, color: AppColor.primary, size: 22)),
        ),
        const SizedBox(height: 28),
        Text('Forgot password?',
            style: TextStyle(color: textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
        const SizedBox(height: 6),
        Text('Enter your email and we\'ll send you a reset link',
            style: TextStyle(color: textMuted, fontSize: 14)),
        const SizedBox(height: 36),

        Text('Email', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: textPrimary, fontSize: 14),
            cursorColor: AppColor.primary,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'you@example.com',
              hintStyle: TextStyle(color: textMuted, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColor.primary.withValues(alpha: 0.5),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Send Reset Link', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  final Color textPrimary;
  final Color textMuted;

  const _SuccessView({required this.email, required this.textPrimary, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColor.income.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Center(child: PhosphorIcon(PhosphorIconsLight.paperPlaneTilt, color: AppColor.income, size: 22)),
        ),
        const SizedBox(height: 28),
        Text('Check your inbox', style: TextStyle(color: textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: TextStyle(color: textMuted, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'We sent a password reset link to\n'),
              TextSpan(text: email, style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.w600)),
              const TextSpan(text: '. Check your spam folder if you don\'t see it.'),
            ],
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
