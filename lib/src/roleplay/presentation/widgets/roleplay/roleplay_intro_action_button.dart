part of '../../../roleplay.dart';

class RoleplayIntroActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const RoleplayIntroActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        width: double.infinity,
        child: DButton(
          onPressed: onPressed,
          text: label,
          size: Size.fromHeight(54.h),
          backgroundColor: AppCustomColor.brandPrimary,
          shape: const StadiumBorder(),
          style: AppStyle.text16.copyWith(
            fontWeight: FontWeight.w600,
            color: AppCustomColor.textWhite,
          ),
        ),
      ),
    );
  }
}
