part of '../../../roleplay.dart';

class RoleplayIntroDetails extends StatelessWidget {
  const RoleplayIntroDetails({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RoleplayCubit, RoleplayState, LessonEntity>(
      selector: (state) => state.currentLesson,
      builder: (context, lesson) {
        String timeText = lesson.estimateCompleTime.text;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (timeText.isNotEmpty) ...[
              RoleplayIntroTimeChip(text: timeText),
              16.verticalSpace,
            ],
            AppText(
              lesson.title.text,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: AppStyle.text24.copyWith(
                fontWeight: FontWeight.w700,
                color: AppCustomColor.textWhite,
                height: 36 / 24,
              ),
            ),
            8.verticalSpace,
            AppText(
              lesson.description.text,
              maxLines: 100,
              textAlign: TextAlign.left,
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
                height: 24 / 16,
              ),
            ),
          ],
        );
      },
    );
  }
}
