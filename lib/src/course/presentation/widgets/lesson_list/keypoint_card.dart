part of '../../../course.dart';

class KeypointCard extends StatelessWidget {
  final KeypointModel keypoint;
  final bool isCompleted;
  final StrengthLevel strengthLevel;
  final VoidCallback? onTap;

  const KeypointCard({
    super.key,
    required this.keypoint,
    this.isCompleted = false,
    this.strengthLevel = StrengthLevel.optional,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion check icon
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: CompletionCheckIcon(isCompleted: isCompleted),
          ),
          SizedBox(width: 16.w),

          // Card content
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                border: Border.all(
                  color: isCompleted
                      ? AppCustomColor.brandPrimary
                      : AppCustomColor.borderDefault,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Strength indicator badge
                  StrengthIndicatorBadge(level: strengthLevel),
                  SizedBox(width: 8.w),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label based on strength level
                        AppText(
                          _getStrengthLabel(),
                          style: AppStyle.text12.copyWith(
                            color: AppCustomColor.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.h),

                        // Keypoint title
                        AppText(
                          keypoint.title.text,
                          style: AppStyle.text14.copyWith(
                            color: AppCustomColor.textSecondary,
                            height: 1.75,
                          ),
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

  String _getStrengthLabel() {
    switch (strengthLevel) {
      case StrengthLevel.weak:
        return 'Weak point';
      case StrengthLevel.morePractice:
        return 'More practice';
      case StrengthLevel.optional:
        return 'Optional Practice';
    }
  }
}
