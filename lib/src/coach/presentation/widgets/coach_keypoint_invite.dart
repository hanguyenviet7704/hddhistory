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

  /// Coach có mời hay không, báo ra ngay khi server trả lời — gọi ĐÚNG một lần.
  ///
  /// Trang bên ngoài cần biết để quyết định vẽ gì: màn "Hoàn thành bài học"
  /// giờ chỉ là phao cho trường hợp Coach tắt. Không có callback này thì trạng
  /// thái đó nằm kín trong BlocProvider của widget và ngoài kia không đọc được.
  final ValueChanged<bool>? onResolved;

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
    this.onResolved,
  });

  /// Luồng 7 already asked on this trip out of the lesson, so this one stays
  /// quiet.
  ///
  /// The two invitations sit back to back — the habit page's runs on Continue,
  /// this one on the completion screen right after it — and a reader who has
  /// just been asked to practise a habit does not also want to be asked to talk
  /// about the keypoint (owner, 2026-09-05: "vừa thêm 2 thói quen rồi thì
  /// thôi, mà không thêm thói quen thì cho thảo luận về bài học"). Consumed by
  /// the first invite that reads it, so it cannot silence a later lesson.
  static bool _suppressOnce = false;

  static void suppressNext() => _suppressOnce = true;

  @override
  State<CoachKeypointInvite> createState() => _CoachKeypointInviteState();
}

class _CoachKeypointInviteState extends State<CoachKeypointInvite> {
  bool _shown = false;
  bool _reported = false;

  @override
  Widget build(BuildContext context) {
    // Luồng 7 asked instead; the page still needs its "nothing to offer"
    // answer so its own Continue button appears.
    if (CoachKeypointInvite._suppressOnce) {
      CoachKeypointInvite._suppressOnce = false;
      _shown = true;
      if (!_reported) {
        _reported = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onResolved?.call(false);
        });
      }

      return const SizedBox.shrink();
    }

    if (widget.lessonId.isEmpty || widget.keypointId.isEmpty) {
      // Không đủ dữ liệu để hỏi server ⇒ chắc chắn không mời. Vẫn phải BÁO,
      // không thì trang ngoài đứng ở trạng thái "chưa biết" mãi và user xong
      // bài chỉ còn nút X — không có đường sang bài tiếp theo.
      if (!_reported) {
        _reported = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onResolved?.call(false);
        });
      }

      return const SizedBox.shrink();
    }

    return BlocProvider<CoachBubbleCubit>(
      create: (_) => AppDI.injector.get<CoachBubbleCubit>()..refresh(entry: CoachEntry.lesson, lessonId: widget.lessonId),
      child: BlocListener<CoachBubbleCubit, CoachBubbleState>(
        // Nghe cả trường hợp KHÔNG mời: hai cờ riêng vì `onResolved` phải báo
        // được "Coach tắt" — dùng chung một cờ thì lượt resolve không-visible
        // sẽ khoá luôn lượt mời sau đó.
        listenWhen: (prev, curr) => curr.resolved && !(_reported && _shown),
        listener: (context, state) {
          if (!_reported) {
            _reported = true;
            widget.onResolved?.call(state.visible);
          }
          if (!state.visible || _shown) return;
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
    CoachTracking.inviteScrView(
      lessonId: widget.lessonId,
      keypointId: widget.keypointId,
      courseId: widget.courseId,
      isCourseDone: widget.isCourseDone,
    );

    // Owner 2026-09-05: "bấm đóng thì quay lại màn thực hành với coach chứ
    // không được sang keypoint tiếp".
    //
    // Closing the sheet mid-conversation is not a decision to move on — it is
    // backing out of the sheet. It used to fall through to `onContinue()` and
    // walk the reader into the next keypoint, so the only way to LOOK at the
    // Coach and then not use it was to be pushed forward. The invitation is
    // shown again instead, and the reader leaves it deliberately: ⟨Bỏ qua,
    // sang bài tiếp theo⟩, or a Coach ending that goes to the Roadmap.
    while (true) {
      // Second time round the loop this follows the sheet's own await, so the
      // context has to be re-checked before it opens a dialog.
      if (!context.mounted) return;
      final choice = await CoachInvitePopup.show(
        context,
        kind: widget.isCourseDone ? CoachInviteKind.courseDone : CoachInviteKind.keypoint,
        courseTitle: widget.courseTitle,
      );

      // ✕ — out of the lesson flow altogether, for the course Roadmap.
      if (choice == CoachInviteChoice.exit) {
        if (!mounted) return;
        final navContext = AppConfig.instance.context ?? (context.mounted ? context : null);
        if (navContext != null &&
            navContext.mounted &&
            AppDI.injector.get<DeeplinkCubit>().openCourseRoadmapFromCoach(navContext, widget.courseId)) {
          return;
        }
        // The Roadmap could not be reached (no course id, catalogue gap). Going
        // on beats stranding them on a page with nothing on it.
        if (mounted) widget.onContinue();

        return;
      }

      // Nút thứ hai mang chữ "Bỏ qua, sang bài tiếp theo" (`inviteLater`), nên
      // nó phải đi tiếp thật. Trước đây nó chỉ đóng dialog và rơi về màn "Hoàn
      // thành bài học" phía dưới — mà màn đó đã bỏ, nên không đi tiếp là để
      // user đứng trên một trang trống.
      if (choice != CoachInviteChoice.practice) {
        CoachTracking.inviteLater(
          lessonId: widget.lessonId,
          keypointId: widget.keypointId,
          courseId: widget.courseId,
          isCourseDone: widget.isCourseDone,
        );
        if (mounted) widget.onContinue();

        return;
      }

      CoachTracking.inviteAccept(
        lessonId: widget.lessonId,
        keypointId: widget.keypointId,
        courseId: widget.courseId,
        isCourseDone: widget.isCourseDone,
      );
      if (!context.mounted) return;

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
    //
    // Two destinations reach the same route: a course the Coach offered, and
    // the talk finishing on its own ("Đóng · về Roadmap"). The second one is
    // this course's roadmap, so it uses the id this page already holds.
      final roadmapId = outcome.courseId ?? (outcome.toRoadmap ? widget.courseId : null);
      if (roadmapId != null && roadmapId.isNotEmpty) {
        final navContext = AppConfig.instance.context ?? (context.mounted ? context : null);
        if (navContext != null && navContext.mounted && AppDI.injector.get<DeeplinkCubit>().openCourseRoadmapFromCoach(navContext, roadmapId)) {
          return;
        }
      }
      // Nothing navigated: the sheet was simply closed. Round the loop and
      // offer it again — the page underneath is bare now that the "Hoàn thành
      // bài học" block is gone, so leaving the reader on it is the trap this
      // whole guard exists to avoid.
      if (!mounted) return;
    }
  }
}

/// The invitation itself — the design's "màn mời riêng": the same full frame
/// as the habit-added screen (cửa ①), with one line in a speech bubble over the
/// Coach, one primary button, and ⟨Lúc khác⟩ as plain text. No title, no
/// paragraph, no second card — "chỉ đổi câu và nhãn nút". After the course's
/// last keypoint a small "Hoàn thành khoá học" label sits above the bubble and
/// the line names the course.
/// Which invitation this is — the three share one frame and differ only in the
/// line, the small label above it and the primary button's words.
/// The three ways off the invitation screen.
///
/// Owner 2026-09-05: the screen had only two — practise, or go on to the next
/// keypoint — so a reader who wanted neither had nowhere to go. The page
/// underneath has its own ✕ to the Roadmap, but this covers it.
enum CoachInviteChoice {
  /// ⟨Thực hành với Coach⟩.
  practice,

  /// ⟨Bỏ qua, sang bài tiếp theo⟩.
  next,

  /// ✕ — leave the lesson flow entirely, for the course Roadmap.
  exit,
}

enum CoachInviteKind {
  /// Luồng 2 — after a keypoint: "nói một chút về nó nhé?".
  keypoint,

  /// Luồng 3 — after the course's last keypoint: "nhìn lại một chút nhé?".
  courseDone,

  /// Luồng 7 — habits were just added at the end of a lesson: "tập thử một cái
  /// ngay nhé, lúc còn nhớ vì sao mình thêm?".
  newHabit,
}

class CoachInvitePopup extends StatelessWidget {
  final CoachInviteKind kind;
  final String courseTitle;

  /// Luồng 7 — how many habits were just added; the line counts them.
  final int newHabitCount;

  const CoachInvitePopup._({
    required this.kind,
    required this.courseTitle,
    this.newHabitCount = 0,
  });

  static Future<CoachInviteChoice?> show(
    BuildContext context, {
    required CoachInviteKind kind,
    String courseTitle = '',
    int newHabitCount = 0,
  }) {
    return showGeneralDialog<CoachInviteChoice>(
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
            child: CoachInvitePopup._(kind: kind, courseTitle: courseTitle, newHabitCount: newHabitCount),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final line = switch (kind) {
      CoachInviteKind.courseDone => courseTitle.trim().isEmpty ? l10n.inviteRecapBubbleNoName : l10n.inviteRecapBubble(course: courseTitle.trim()),
      // "Lúc còn nhớ vì sao mình thêm" — why this beat runs here rather than
      // tomorrow from the Habit tab.
      CoachInviteKind.newHabit => newHabitCount > 1 ? l10n.inviteNewHabitsBubble(n: newHabitCount.toString()) : l10n.inviteNewHabitBubble,
      CoachInviteKind.keypoint => l10n.inviteBubble,
    };
    final kicker = switch (kind) {
      CoachInviteKind.courseDone => l10n.inviteCourseDone,
      CoachInviteKind.newHabit => newHabitCount > 1 ? l10n.inviteNewHabitsKicker(n: newHabitCount.toString()) : l10n.inviteNewHabitKicker,
      CoachInviteKind.keypoint => null,
    };
    final accept = switch (kind) {
      CoachInviteKind.courseDone => l10n.inviteRecapAccept,
      CoachInviteKind.newHabit => l10n.inviteNewHabitAccept,
      CoachInviteKind.keypoint => l10n.inviteAccept,
    };

    return Material(
      color: CoachStyle.sheetBackground,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            children: [
              // The way OUT of the lesson flow. The page underneath has the
              // same ✕ and this screen covers it, so without one here the only
              // moves were "practise" and "next keypoint" (owner 2026-09-05).
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Semantics(
                    button: true,
                    label: context.l10n.common.close,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(CoachInviteChoice.exit),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: CoachStyle.surface,
                          shape: BoxShape.circle,
                          boxShadow: CoachStyle.cardShadow,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.close, size: 18.w, color: CoachStyle.textChip),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 5),
              if (kicker != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: CoachStyle.selectedBackground,
                    border: Border.all(color: CoachStyle.selectedBorderSoft),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: Text(
                    kicker,
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
                  onPressed: () => Navigator.of(context).pop(CoachInviteChoice.practice),
                  child: Text(
                    accept,
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
                onPressed: () => Navigator.of(context).pop(CoachInviteChoice.next),
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
