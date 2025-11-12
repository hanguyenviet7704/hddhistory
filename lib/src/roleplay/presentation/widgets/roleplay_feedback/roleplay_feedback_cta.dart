part of '../../../roleplay.dart';

class RoleplayFeedbackBottomCTA extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final String helperText;

  const RoleplayFeedbackBottomCTA({super.key, required this.onPressed, required this.label, required this.helperText});

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomPadding + 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPressed,
            child: Container(
              height: 54.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary,
                borderRadius: BorderRadius.circular(1000.r),
              ),
              alignment: Alignment.center,
              child: AppText(
                label,
                style: AppStyle.text16.copyWith(
                  color: AppCustomColor.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          12.verticalSpace,
          AppText(
            helperText,
            textAlign: TextAlign.center,
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.textTertiary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
