import 'package:flutter/material.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/config/app_theme.dart';

class CustomInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool disabled;
  final EdgeInsetsGeometry margin;
  final bool obsecureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;

  const CustomInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.disabled = false,
    this.margin = const EdgeInsets.only(bottom: AppDimens.spaceLG),
    this.obsecureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillColor = widget.disabled
        ? (isDark ? AppColor.darkElevated : AppColor.lightBg)
        : (isDark ? AppColor.darkSurface : AppColor.lightSurface);

    final borderColor =
        isDark ? AppColor.darkBorder : AppColor.lightBorder;

    final textColor =
        isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;

    final hintColor =
        isDark ? AppColor.textTertiary : AppColor.lightTextTertiary;

    final labelColor =
        isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Container(
      width: double.infinity,
      margin: widget.margin,
      padding: const EdgeInsets.only(left: 14, right: 14, top: 4),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        readOnly: widget.disabled,
        obscureText: widget.obsecureText,
        keyboardType: widget.keyboardType,
        style: AppTypography.body(textColor),
        maxLines: 1,
        controller: widget.controller,
        cursorColor: AppColor.primary,
        decoration: InputDecoration(
          suffixIcon: widget.suffixIcon,
          prefixIcon: widget.prefixIcon,
          label: Text(
            widget.label,
            style: AppTypography.caption(labelColor),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: widget.hint,
          hintStyle: AppTypography.body(hintColor),
        ),
      ),
    );
  }
}
