part of '../../coach.dart';

/// Luồng 2/3 — the invitation after a keypoint.
///
/// Not a bubble and not a popup that fires on its own timer: the design's
/// "màn mời riêng" — the same frame the habit-added screen uses — with one
/// choice. ⟨Thực hành với Coach⟩ opens the sheet straight into the talk;
/// after the course's last keypoint the label reads "Hoàn thành khoá học" and
/// the button is ⟨Nhìn lại cả khoá⟩. ⟨Lúc khác⟩ closes and nothing is counted.
///
/// The server still decides whether the Coach is available at all
/// (`getBubble`, entry lesson); this widget only decides WHEN — once, after
/// the page's first frame.
class CoachKeypointInvite extends StatefulWidget {
  final String lessonId;
  final String keypointId;
  final String courseId;
  final bool isCourseDone;
  final List<QuestionEntity> quizQuestions;
  final String quizTitle;
  /// ⟨Học tiếp⟩ inside the sheet — the page goes on to the next keypoint.
  final VoidCallback onContinue;

  const CoachKeypointInvite({
    super.key,
    required this.lessonId,
    required this.keypointId,
    required this.courseId,
    required this.isCourseDone,
    required this.quizQuestions,
    required this.quizTitle,
    required this.onContinue,
  });

  @override
  State<CoachKeypointInvite> createState() => _CoachKeypointInviteState();
}

class _CoachKeypointInviteState extends State<CoachKeypointInvite> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (widget.lessonId.isEmpty || widget.keypointId.isEmpty) return const SizedBox.shrink();

    return BlocProvider<CoachBubbleCubit>(
      create: (_) => AppDI.injector.get<CoachBubbleCubit>()..refresh(entry: CoachEntry.lesson, lessonId: widget.lessonId),
      child: BlocListener<CoachBubbleCubit, CoachBubbleState>(
        listenWhen: (prev, curr) => curr.resolved && curr.visible && !_shown,
        listener: (context, state) {
          _shown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _invite(context);
          });
        },
        child: const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _invite(BuildContext context) async {
    final accepted = await CoachInvitePopup.show(context, isCourseDone: widget.isCourseDone);
    if (accepted != true || !context.mounted) return;

    final outcome = await showCoachSheetForKeypoint(
      context,
      entry: CoachEntry.lesson,
      lessonId: widget.lessonId,
      keypointId: widget.isCourseDone ? null : widget.keypointId,
      courseId: widget.isCourseDone ? widget.courseId : null,
      recap: widget.isCourseDone,
      quizQuestions: widget.quizQuestions,
      quizTitle: widget.quizTitle,
    );

    // Navigation happens only AFTER the modal is gone, through the app-level
    // context — the lesson surface under the sheet may itself be gone by then.
    if (outcome.courseId != null) {
      final navContext = AppConfig.instance.context ?? (context.mounted ? context : null);
      if (navContext != null && navContext.mounted) {
        AppDI.injector.get<DeeplinkCubit>().openCourseRoadmapFromCoach(navContext, outcome.courseId!);
      }

      return;
    }
    if (outcome.nextKeypoint && mounted) widget.onContinue();
  }
}

/// The invitation itself — the habit-added frame with one decision on it.
class CoachInvitePopup extends StatelessWidget {
  final bool isCourseDone;

  const CoachInvitePopup._({required this.isCourseDone});

  static Future<bool?> show(BuildContext context, {required bool isCourseDone}) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'coachInvitePopup',
      barrierColor: AppCustomColor.scrimOverlay,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, _) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: CoachInvitePopup._(isCourseDone: isCourseDone),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCourseDone) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppCustomColor.brandPrimary50,
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                      child: AppText(
                        l10n.inviteCourseDone,
                        style: AppStyle.text12.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.brandPrimary),
                      ),
                    ),
                    10.verticalSpace,
                  ],
                  AppText(
                    isCourseDone ? l10n.inviteRecapTitle : l10n.inviteTitle,
                    textAlign: TextAlign.center,
                    style: AppStyle.text22.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
                  ),
                  4.verticalSpace,
                  AppText(
                    isCourseDone ? l10n.inviteRecapSubtitle : l10n.inviteSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 100,
                    style: AppStyle.text13.copyWith(color: AppCustomColor.textSecondary),
                  ),
                  24.verticalSpace,
                  DButton(
                    text: isCourseDone ? l10n.inviteRecapAccept : l10n.inviteAccept,
                    backgroundColor: AppCustomColor.brandPrimary,
                    size: Size(double.infinity, 54.h),
                    style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  8.verticalSpace,
                  DButton(
                    text: l10n.inviteLater,
                    backgroundColor: AppCustomColor.brandPrimary50,
                    size: Size(double.infinity, 54.h),
                    style: AppStyle.textBold16.copyWith(color: AppCustomColor.streakActive),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
