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
    return Container(
      height: maxLines == 1 ? 80.h : null,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEAFD), // Background/Brand
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFC7C5FA), // Border/Brand
          width: 2.w,
        ),
      ),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        textAlign: TextAlign.center,
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
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }
}
