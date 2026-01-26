part of '../../feedback.dart';

class FeedbackCompleteLessonPopup extends StatelessWidget {
  const FeedbackCompleteLessonPopup({super.key});

  static Future<void> show(
    BuildContext context, {
    FeedbackEntry entry = FeedbackEntry.roleplay,
  }) {
    context.read<FeedbackCubit>().setActiveFeedback(
      type: FeedbackType.complete,
      entry: entry,
    );
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'feedbackCompleteLessonPopup',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, _) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: const FeedbackCompleteLessonPopup(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedbackCubit, FeedbackState>(
      builder: (context, state) {
        final cubit = context.read<FeedbackCubit>();
        final overallRating = _calculateOverallRating(
          state.draftContentRating,
          state.draftExperienceRating,
        );
        final isLoading = state.status == FeedbackStatus.loading;
        final canSubmit = state.draftContentRating > 0 && state.draftExperienceRating > 0 && !isLoading;

        return FeedbackPopupShell(
          onTapOutside: () => context.pop(),
          child: Container(
            width: 327.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
                        rating: overallRating,
                        starSize: 36,
                        spacing: 6,
                        alignment: MainAxisAlignment.center,
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
                          onRatingChanged: cubit.updateContentRating,
                          starSize: 24,
                          spacing: 4,
                        ),
                        16.verticalSpace,
                        FeedbackRatingRow(
                          label: context.text.feedback.experienceLabel,
                          rating: state.draftExperienceRating,
                          onRatingChanged: cubit.updateExperienceRating,
                          starSize: 24,
                          spacing: 4,
                        ),
                        16.verticalSpace,
                        FeedbackCommentField(
                          value: state.draftComment,
                          hint: context.text.feedback.commentHint,
                          onChanged: cubit.updateComment,
                        ),
                        24.verticalSpace,
                        FeedbackPrimaryButton(
                          title: context.text.feedback.sendFeedback,
                          enabled: canSubmit,
                          onTap: cubit.submitFeedback,
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

  int _calculateOverallRating(int contentRating, int experienceRating) {
    if (contentRating == 0 || experienceRating == 0) {
      return 0;
    }
    final average = (contentRating + experienceRating) / 2;
    return average.round();
  }
}
