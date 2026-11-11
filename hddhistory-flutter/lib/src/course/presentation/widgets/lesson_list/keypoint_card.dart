part of '../../../course.dart';

class KeypointCard extends StatelessWidget {
  final KeypointEntity keypoint;
  final VoidCallback? onTap;

  const KeypointCard({
    super.key,
    required this.keypoint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              AppHaptic.select();
              onTap!();
            },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Completion check icon
          CompletionCheckIcon(isCompleted: keypoint.isCompleted),
          16.horizontalSpace,

          // Card content
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                border: Border.all(
                  color: keypoint.isCompleted ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Strength indicator badge
                  StrengthIndicatorBadge(level: keypoint.strengthLevel),
                  8.horizontalSpace,

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label based on strength level
                        AppText(
                          keypoint.strengthLevel.title(context),
                          style: AppStyle.text12.copyWith(
                            color: AppCustomColor.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        4.verticalSpace,

                        // Keypoint title
                        AppText(
                          keypoint.title.text,
                          style: AppStyle.text14.copyWith(
                            color: AppCustomColor.textSecondary,
                            height: 1.75,
                          ),
                          maxLines: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
