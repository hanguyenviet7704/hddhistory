part of '../../feedback.dart';

class FeedbackIncompleteLessonPopup extends StatefulWidget {
  const FeedbackIncompleteLessonPopup({super.key});

  static Future<void> show(
    BuildContext context, {
    FeedbackEntry entry = FeedbackEntry.roleplay,
    required String courseId,
    required String lessonId,
    required String keypointId,
  }) {
    context.read<FeedbackCubit>().setActiveFeedback(
      type: FeedbackType.incomplete,
      entry: entry,
      courseId: courseId,
      lessonId: lessonId,
      keypointId: keypointId,
    );
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'feedbackIncompleteLessonPopup',
      barrierColor: AppCustomColor.scrimOverlay,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      routeSettings: const RouteSettings(name: RouteNamed.feedbackIncompleteLessonPopup),
      transitionBuilder: (context, animation, _, _) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: BlocProvider.value(
              value: AppDI.injector.get<FeedbackCubit>(),
              child: const FeedbackIncompleteLessonPopup(),
            ),
          ),
        );
      },
    );
  }

  @override
  State<FeedbackIncompleteLessonPopup> createState() => _FeedbackIncompleteLessonPopupState();
}

class _FeedbackIncompleteLessonPopupState extends State<FeedbackIncompleteLessonPopup> {
  bool _submitted = false;
  bool _hasShownThankYou = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<FeedbackCubit, FeedbackState>(
      listenWhen: (previous, current) => previous.status != current.status && current.status == FeedbackStatus.success,
      listener: (context, state) {
        if (!_submitted || _hasShownThankYou) return;
        _hasShownThankYou = true;
        _submitted = false;
        context.back();
        Future.microtask(() {
          if (!context.mounted) return;
          FeedbackBeforeYouGoPopup.show(context);
        });
      },
      child: BlocBuilder<FeedbackCubit, FeedbackState>(
        builder: (context, state) {
          final cubit = context.read<FeedbackCubit>();
          final labels = _buildReasonLabels(context);
          final isLoading = state.status == FeedbackStatus.loading;
          final canSubmit = (state.draftReasons.isNotEmpty || state.draftComment.trim().isNotEmpty) && !isLoading;

          return FeedbackPopupShell(
            onTapOutside: () => context.back(),
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
                    padding: EdgeInsets.fromLTRB(12.w, 24.h, 12.w, 24.h),
                    child: FeedbackHeader(
                      title: context.text.feedback.incompleteTitle,
                      subtitle: context.text.feedback.incompleteSubtitle,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            context.text.feedback.incompleteReasonTitle,
                            style: AppStyle.text14.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppCustomColor.textSecondary,
                              height: 1.75,
                            ),
                          ),
                          6.verticalSpace,
                          FeedbackReasonList(
                            labels: labels,
                            selected: state.draftReasons,
                            onToggle: cubit.toggleReason,
                          ),
                          24.verticalSpace,
                          FeedbackCommentField(
                            value: state.draftComment,
                            hint: context.text.feedback.commentHint,
                            onChanged: cubit.updateComment,
                          ),
                          32.verticalSpace,
                          FeedbackPrimaryButton(
                            title: context.text.feedback.sendFeedback,
                            enabled: canSubmit,
                            onTap: () {
                              if (!canSubmit) return;
                              _submitted = true;
                              cubit.submitFeedback();
                            },
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
      ),
    );
  }

  Map<IncompleteFeedbackReason, String> _buildReasonLabels(BuildContext context) {
    return {
      IncompleteFeedbackReason.hardToUnderstand: context.text.feedback.reasonHardToUnderstand,
      IncompleteFeedbackReason.notEngaging: context.text.feedback.reasonNotEngaging,
      IncompleteFeedbackReason.poorVisuals: context.text.feedback.reasonPoorVisuals,
      IncompleteFeedbackReason.hardQuestions: context.text.feedback.reasonHardQuestions,
      IncompleteFeedbackReason.needsMoreExamples: context.text.feedback.reasonNeedsMoreExamples,
    };
  }
}
