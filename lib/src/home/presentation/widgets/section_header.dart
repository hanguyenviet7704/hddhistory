part of '../../home.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Section title
          AppText(title, style: AppStyle.textBold16),
          // Action button
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    actionText!,
                    style: AppStyle.textBold12.copyWith(
                      color: AppCustomColor.brandPrimary,
                    ),
                  ),
                  4.horizontalSpace,
                  Icon(Icons.arrow_forward_ios, color: AppCustomColor.brandPrimary, size: 16.sp),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
