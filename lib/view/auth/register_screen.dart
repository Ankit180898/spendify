import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/auth_controller/register_controller.dart';
import 'package:spendify/routes/app_pages.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterController());
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
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account?',
                    style: TextStyle(color: textMuted, fontSize: 14)),
                TextButton(
                  onPressed: () => Get.toNamed(Routes.LOGIN),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                  child: const Text('Sign in',
                      style: TextStyle(color: AppColor.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsLight.wallet,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 28),
                Text('Create account',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    )),
                const SizedBox(height: 6),
                Text('Start tracking your finances today',
                    style: TextStyle(color: textMuted, fontSize: 14)),
                const SizedBox(height: 36),

                Text('Full name',
                    style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _Field(
                  controller: controller.nameC,
                  hint: 'John Doe',
                  keyboardType: TextInputType.name,
                  inputBg: inputBg,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  autofillHints: const [AutofillHints.name],
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                Text('Email',
                    style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _Field(
                  controller: controller.emailC,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  inputBg: inputBg,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  autofillHints: const [AutofillHints.newUsername],
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 16),

                Text('Password',
                    style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Obx(() => _Field(
                      controller: controller.passwordC,
                      hint: '••••••••',
                      obscure: controller.isHidden.value,
                      inputBg: inputBg,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      autofillHints: const [AutofillHints.newPassword],
                      autocorrect: false,
                      enableSuggestions: false,
                      suffix: GestureDetector(
                        onTap: () => controller.isHidden.value = !controller.isHidden.value,
                        child: PhosphorIcon(
                          controller.isHidden.value
                              ? PhosphorIconsLight.eye
                              : PhosphorIconsLight.eyeSlash,
                          color: textMuted,
                          size: 18,
                        ),
                      ),
                    )),
                const SizedBox(height: 32),

                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.isFalse
                            ? () => controller.register()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColor.primary.withValues(alpha: 0.5),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isLoading.isTrue
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Create Account',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Color inputBg;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final List<String>? autofillHints;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;

  const _Field({
    required this.controller,
    required this.hint,
    required this.inputBg,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.autofillHints,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: widget.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? AppColor.primary : widget.border,
            width: _focused ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscure,
                keyboardType: widget.keyboardType,
                autocorrect: widget.autocorrect,
                enableSuggestions: widget.enableSuggestions,
                autofillHints: widget.autofillHints,
                textCapitalization: widget.textCapitalization,
                style: TextStyle(color: widget.textPrimary, fontSize: 14),
                cursorColor: AppColor.primary,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: widget.textMuted, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (widget.suffix != null) ...[const SizedBox(width: 8), widget.suffix!],
          ],
        ),
      );
}
