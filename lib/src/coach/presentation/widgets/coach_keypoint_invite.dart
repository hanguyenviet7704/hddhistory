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

  /// Named in the course-complete line — "Bạn vừa xong cả khoá «X»". Empty
  /// falls back to the line without a name.
  final String courseTitle;
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
    this.courseTitle = '',
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
    final accepted = await CoachInvitePopup.show(
      context,
      isCourseDone: widget.isCourseDone,
      courseTitle: widget.courseTitle,
    );
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

/// The invitation itself — the design's "màn mời riêng": the same full frame
/// as the habit-added screen (cửa ①), with one line in a speech bubble over the
/// Coach, one primary button, and ⟨Lúc khác⟩ as plain text. No title, no
/// paragraph, no second card — "chỉ đổi câu và nhãn nút". After the course's
/// last keypoint a small "Hoàn thành khoá học" label sits above the bubble and
/// the line names the course.
class CoachInvitePopup extends StatelessWidget {
  final bool isCourseDone;
  final String courseTitle;

  const CoachInvitePopup._({required this.isCourseDone, required this.courseTitle});

  static Future<bool?> show(BuildContext context, {required bool isCourseDone, String courseTitle = ''}) {
    return showGeneralDialog<bool>(
      context: context,
      // A full screen with its own ⟨Lúc khác⟩: tapping outside is not a way out
      // because there is no outside.
      barrierDismissible: false,
      barrierLabel: 'coachInvitePopup',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, _) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
            child: CoachInvitePopup._(isCourseDone: isCourseDone, courseTitle: courseTitle),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final line = isCourseDone ? (courseTitle.trim().isEmpty ? l10n.inviteRecapBubbleNoName : l10n.inviteRecapBubble(course: courseTitle.trim())) : l10n.inviteBubble;

    return Material(
      color: CoachStyle.sheetBackground,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            children: [
              const Spacer(flex: 5),
              if (isCourseDone) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: CoachStyle.selectedBackground,
                    border: Border.all(color: CoachStyle.selectedBorderSoft),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: Text(
                    l10n.inviteCourseDone,
                    style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: CoachStyle.selectedText),
                  ),
                ),
                SizedBox(height: 14.h),
              ],
              _SpeechBubble(text: line),
              SizedBox(height: 10.h),
              const CoachSlime(mood: CoachSlimeMood.waiting, size: 84, shadow: true),
              SizedBox(height: 14.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.sheetTitle,
                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: CoachStyle.textPrimary),
                  ),
                  SizedBox(width: 6.w),
                  // The same stage marker the sheet's header wears — a literal.
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: CoachStyle.selectedBackground,
                      border: Border.all(color: CoachStyle.selectedBorderSoft),
                      borderRadius: BorderRadius.circular(99.r),
                    ),
                    child: Text(
                      'BETA',
                      style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: CoachStyle.userBubble),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 6),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: CoachStyle.userBubble,
                    foregroundColor: CoachStyle.surface,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    isCourseDone ? l10n.inviteRecapAccept : l10n.inviteAccept,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: CoachStyle.textMuted,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  l10n.inviteLater,
                  style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Coach's line in a white bubble with a small tail pointing down at it —
/// the design's speech balloon over the avatar.
class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: 300.w),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: CoachStyle.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: CoachStyle.cardShadow,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, height: 1.45, color: CoachStyle.textPrimary),
          ),
        ),
        // The tail: a rotated square tucked under the bubble's bottom edge.
        Transform.translate(
          offset: Offset(0, -7.h),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(color: CoachStyle.surface, borderRadius: BorderRadius.circular(2.r)),
            ),
          ),
        ),
      ],
    );
  }
}
