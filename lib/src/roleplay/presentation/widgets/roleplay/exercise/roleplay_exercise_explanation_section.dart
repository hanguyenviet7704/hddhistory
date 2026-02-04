part of '../../../../roleplay.dart';

class _RoleplayExerciseExplanationSection extends StatelessWidget {
  final String explanationText;

  const _RoleplayExerciseExplanationSection({
    required this.explanationText,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppCustomColor.roleplayExplanationBackground,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                t.exercise.exerciseExplanationTitle.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: AppStyle.text12.copyWith(
                  color: AppCustomColor.textWhite.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              4.verticalSpace,
              AppText(
                explanationText,
                maxLines: 10,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textWhite,
                  fontWeight: FontWeight.w400,
                  height: 1.75,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
