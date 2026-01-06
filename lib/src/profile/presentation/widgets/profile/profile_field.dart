part of '../../../profile.dart';

class ProfileFieldDisplay extends StatelessWidget {
  const ProfileFieldDisplay({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textQuaternary,
            height: 1.75,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value.isNotEmpty ? value : '-',
          style: AppStyle.text16.copyWith(
            color: AppCustomColor.textSecondary,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class ProfileEditableField extends StatelessWidget {
  const ProfileEditableField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.name,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyle.text10.copyWith(
            color: AppCustomColor.textQuaternary,
            height: 1.75,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.done,
          style: AppStyle.text16.copyWith(
            color: AppCustomColor.textSecondary,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
          onSubmitted: (_) => onSubmitted?.call(),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppCustomColor.backgroundWhite,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppCustomColor.brandPrimary, width: 2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppCustomColor.brandPrimary, width: 2),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileReadonlyField extends StatelessWidget {
  const ProfileReadonlyField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyle.text10.copyWith(
            color: AppCustomColor.textQuaternary,
            height: 1.75,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundGray,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            value.isNotEmpty ? value : '-',
            style: AppStyle.text16.copyWith(
              color: AppCustomColor.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
