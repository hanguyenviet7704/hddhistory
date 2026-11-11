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
    final trackingData = _feedbackCourseTrackingData(context, courseId);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackFeedbackIncompleteLessonView(
        trackingData,
        source: _feedbackSourceFromEntry(entry),
      );
    }
    // Spec event (sheet "9. Exit feedback"), fired alongside the existing
    // feedback_incomplete_lesson_view telemetry.
    AppService.instance.appTrackingService.trackEvent(TrackingKey.exitFeedbackScrView);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
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
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: AppDI.injector.get<FeedbackCubit>()),
                BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
              ],
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
      child: FeedbackPopupShell(
        onTapOutside: () {
          // Dismiss without sending = exit feedback close (spec "9. Exit feedback").
          AppService.instance.appTrackingService.trackEvent(TrackingKey.exitFeedbackCloseClick);
          context.back();
        },
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
                  title: context.l10n.feedback.incompleteTitle,
                  subtitle: context.l10n.feedback.incompleteSubtitle,
                  // ✕ dismiss = same as tapping outside (spec "9. Exit feedback"
                  // close): log the close event, then pop without sending.
                  onClose: () {
                    AppService.instance.appTrackingService.trackEvent(TrackingKey.exitFeedbackCloseClick);
                    context.back();
                  },
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
                  child: BlocBuilder<FeedbackCubit, FeedbackState>(
                    builder: (context, state) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            context.l10n.feedback.incompleteReasonTitle,
                            style: AppStyle.text14.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppCustomColor.textSecondary,
                              height: 1.75,
                            ),
                          ),
                          6.verticalSpace,
                          FeedbackReasonList(
                            labels: IncompleteFeedbackReasonListExtension.buildReasonLabels(context),
                            selected: state.draftReasons,
                            onToggle: context.read<FeedbackCubit>().toggleReason,
                          ),
                          24.verticalSpace,
                          FeedbackCommentField(
                            value: state.draftComment,
                            hint: context.l10n.feedback.commentHint,
                            onChanged: context.read<FeedbackCubit>().updateComment,
                          ),
                          32.verticalSpace,
                          FeedbackPrimaryButton(
                            title: context.l10n.feedback.sendFeedback,
                            enabled: state.feedbackIncompleteCanSubmit,
                            onTap: () {
                              if (!state.feedbackIncompleteCanSubmit) return;
                              final trackingData = _feedbackCourseTrackingData(context, state.activeCourseId);
                              if (trackingData != null) {
                                AppService.instance.appTrackingService.trackFeedbackIncompleteLessonSend(
                                  trackingData,
                                  source: _feedbackSourceFromEntry(state.activeEntry),
                                );
                              }
                              _submitted = true;
                              // Spec event (sheet "9. Exit feedback").
                              AppService.instance.appTrackingService.trackEvent(TrackingKey.exitFeedbackSendClick);
                              context.read<FeedbackCubit>().submitFeedback();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
