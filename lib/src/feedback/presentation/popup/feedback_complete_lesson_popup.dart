part of '../../feedback.dart';

class FeedbackCompleteLessonPopup extends StatelessWidget {
  const FeedbackCompleteLessonPopup({super.key});

  static Future<void> show(
    BuildContext context, {
    FeedbackEntry entry = FeedbackEntry.roleplay,
    required String courseId,
    required String lessonId,
    required String keypointId,
  }) {
    context.read<FeedbackCubit>().setActiveFeedback(
      type: FeedbackType.complete,
      entry: entry,
      courseId: courseId,
      lessonId: lessonId,
      keypointId: keypointId,
    );
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'feedbackCompleteLessonPopup',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      routeSettings: const RouteSettings(name: RouteNamed.feedbackCompleteLessonPopup),
      transitionBuilder: (context, animation, _, _) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: BlocProvider.value(
              value: AppDI.injector.get<FeedbackCubit>(),
              child: const FeedbackCompleteLessonPopup(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedbackCubit, FeedbackState>(
      builder: (context, state) {
        return FeedbackPopupShell(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppCustomColor.backgroundWhite,
                  AppCustomColor.feedbackGradientMid,
                  AppCustomColor.feedbackGradientEnd,
                ],
                stops: const [0.253, 0.701, 1],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 24.h, 12.w, 16.h),
                  child: Column(
                    children: [
                      FeedbackHeader(title: context.text.feedback.completeTitle),
                      12.verticalSpace,
                      FeedbackRatingRow(
                        rating: state.draftOverallRating,
                        starSize: 36,
                        spacing: 6,
                        alignment: MainAxisAlignment.center,
                        onRatingChanged: context.read<FeedbackCubit>().updateOverallRating,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppCustomColor.backgroundWhite,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FeedbackRatingRow(
                          label: context.text.feedback.contentLabel,
                          rating: state.draftContentRating,
                          onRatingChanged: context.read<FeedbackCubit>().updateContentRating,
                          starSize: 24,
                          spacing: 4,
                        ),
                        16.verticalSpace,
                        FeedbackRatingRow(
                          label: context.text.feedback.experienceLabel,
                          rating: state.draftExperienceRating,
                          onRatingChanged: context.read<FeedbackCubit>().updateExperienceRating,
                          starSize: 24,
                          spacing: 4,
                        ),
                        16.verticalSpace,
                        FeedbackCommentField(
                          value: state.draftComment,
                          hint: context.text.feedback.commentHint,
                          onChanged: context.read<FeedbackCubit>().updateComment,
                        ),
                        24.verticalSpace,
                        FeedbackPrimaryButton(
                          title: context.text.feedback.sendFeedback,
                          enabled: state.canSubmit,
                          onTap: context.read<FeedbackCubit>().submitFeedback,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
