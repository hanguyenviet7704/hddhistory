part of '../../../data_collect.dart';

class OnboardingInput extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;

  const OnboardingInput({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveKeyboardType = keyboardType ?? TextInputType.name;
    final isSingleLine = maxLines == 1;

    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      keyboardType: effectiveKeyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: 1,
      textAlignVertical: TextAlignVertical.center,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      autofillHints: obscureText ? null : const [AutofillHints.name],
      scrollPadding: EdgeInsets.only(bottom: 120.h),
      style: AppStyle.text20.copyWith(
        color: const Color(0xFF917FF6), // Brand/Brand/Primary/300
        fontWeight: FontWeight.normal,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppStyle.text20.copyWith(
          color: const Color(0xFF917FF6), // Brand/Brand/Primary/300
          fontWeight: FontWeight.normal,
        ),
        fillColor: AppCustomColor.backgroundBrand,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppCustomColor.borderBrand, width: 2.w),
          borderRadius: BorderRadius.circular(16.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppCustomColor.borderBrand, width: 2.w),
          borderRadius: BorderRadius.circular(16.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppCustomColor.borderBrand, width: 2.w),
          borderRadius: BorderRadius.circular(16.r),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
        isDense: true,
        filled: true,
      ),
    );
  }
}
