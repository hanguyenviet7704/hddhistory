part of '../../../../roleplay.dart';

class _CollapsedExerciseBody extends StatelessWidget {
  final String questionText;
  final VoidCallback? onTapToAnswer;

  const _CollapsedExerciseBody({
    required this.questionText,
    this.onTapToAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final Translations t = Translations.of(context);

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            questionText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.text20.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          24.verticalSpace,
          Center(
            child: AppText(
              t.roleplay.rolePlayExerciseTapToAnswer,
              maxLines: 2,
              onTap: () {
                AppHaptic.select();
                final trackingData = RoleplayTrackingData.fromContext();
                if (trackingData != null) {
                  AppService.instance.appTrackingService.trackRoleplayQuizClick(trackingData);
                }
                onTapToAnswer?.call();
              },
              textAlign: TextAlign.center,
              style: AppStyle.text16.copyWith(
                color: AppCustomColor.brandPrimary,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
