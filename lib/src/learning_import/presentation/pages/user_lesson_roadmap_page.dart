part of '../../learning_import.dart';

/// The roadmap of a lesson the reader generated — where an import lands.
///
/// This replaced a page that did nothing but fetch and hand off: generation used
/// to drop the reader straight into the deck, which meant the thing they had just
/// made never existed as a place they could come back to. It does now, and it is
/// shaped like the catalogue's roadmap on purpose — same section card, same node
/// column, same floating CTA — because "a course I made" should read as a course.
///
/// **Two nodes, not three.** The design draws a third, an AI coach to ask about
/// what stayed unclear. There is no coach: not in this app, not behind any
/// endpoint. Drawing it would be a button that leads nowhere, so it is left out
/// until the feature it points at exists.
class UserLessonRoadmapPage extends StatefulWidget {
  const UserLessonRoadmapPage({required this.lessonId, super.key});

  final String lessonId;

  @override
  State<UserLessonRoadmapPage> createState() => _UserLessonRoadmapPageState();
}

class _UserLessonRoadmapPageState extends State<UserLessonRoadmapPage> {
  /// Whether a practice conversation already exists for this lesson.
  ///
  /// Page state rather than cubit state: the roadmap is the only screen that
  /// asks, the answer is one bool, and the alternative is a field on
  /// [UserLessonState] that every other consumer would have to ignore.
  bool _practiceStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<UserLessonCubit>().openLesson(widget.lessonId));
      unawaited(_loadPracticeState());
    });
  }

  /// Silent on failure, and that is the point: the practice node is drawn either
  /// way, and a dropped request should cost a tick mark, not the screen.
  Future<void> _loadPracticeState() async {
    final result = await AppDI.injector
        .get<GetOutputPracticeConversationUseCase>()
        .call(UserLessonCourseMapper.practiceSectionId(widget.lessonId))
        .run();

    if (!mounted) return;

    result.fold(
      (_) => null,
      (conversation) {
        if (!conversation.hasConversation) return;
        setState(() => _practiceStarted = true);
      },
    );
  }

  /// Into the deck, at the card they stopped on.
  void _openReader(UserLessonEntity lesson) {
    if (lesson.keypoints.isEmpty) return;

    startImportedKeypointLesson(
      lessonCubit: AppDI.injector.get<LessonCubit>(),
      courseLessonCubit: AppDI.injector.get<CourseLessonCubit>(),
      navContext: context,
      userLesson: lesson,
      keypointIndex: lesson.stopAtKeypointIndex.clamp(
        0,
        lesson.keypoints.length - 1,
      ),
    );
  }

  /// Into the practice chat, keyed by this lesson rather than a roadmap node.
  /// The server recognises the prefix and builds the AI's brief from the lesson
  /// itself — see `UserLessonPracticeService` on the API side.
  void _openPractice() {
    AppHaptic.select();
    OutputPracticeRoute(
      sectionId: UserLessonCourseMapper.practiceSectionId(widget.lessonId),
    ).push(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(
        context,
        AppCustomColor.backgroundWhite,
      ),
      body: ThemedBackground(
        child: BlocBuilder<UserLessonCubit, UserLessonState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.selected != current.selected,
          builder: (context, state) {
            final lesson = state.selected;

            if (lesson == null || lesson.id != widget.lessonId) {
              return SafeBody(
                child: state.status == UserLessonStatus.failure
                    ? _RoadmapError(message: context.l10n.learningImport.errorGeneric)
                    : const Center(child: CircularProgressIndicator()),
              );
            }

            return _RoadmapBody(
              lesson: lesson,
              practiceStarted: _practiceStarted,
              onOpenReader: () => _openReader(lesson),
              onOpenPractice: _openPractice,
            );
          },
        ),
      ),
    );
  }
}

class _RoadmapError extends StatelessWidget {
  const _RoadmapError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: AppText(
          message,
          textAlign: TextAlign.center,
          style: AppStyle.text14.copyWith(
            color: studyThemeOnBg(context, AppCustomColor.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _RoadmapBody extends StatelessWidget {
  const _RoadmapBody({
    required this.lesson,
    required this.practiceStarted,
    required this.onOpenReader,
    required this.onOpenPractice,
  });

  final UserLessonEntity lesson;
  final bool practiceStarted;
  final VoidCallback onOpenReader;
  final VoidCallback onOpenPractice;

  /// Read through to the end of the last keypoint. Both indexes are checked:
  /// resuming at the final keypoint is not the same as having finished it.
  bool get _readDone {
    final keypoints = lesson.keypoints;
    if (keypoints.isEmpty) return false;

    final lastKeypoint = keypoints.length - 1;
    if (lesson.stopAtKeypointIndex < lastKeypoint) return false;

    return lesson.stopAtSectionIndex >= keypoints.last.sections.length - 1;
  }

  bool get _readStarted =>
      lesson.stopAtKeypointIndex > 0 || lesson.stopAtSectionIndex > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;
    final done = (_readDone ? 1 : 0) + (practiceStarted ? 1 : 0);

    return Stack(
      children: [
        SafeBody(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24.w,
              0,
              24.w,
              // Clear of the floating CTA, which is not part of the scroll.
              floatingNavBarHeight(context) + 120.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _RoadmapHeader(),
                Center(
                  child: AppText(
                    lesson.title,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold24.copyWith(
                      fontSize: 23.sp,
                      height: 1.3,
                      color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                    ),
                    maxLines: 3,
                  ),
                ),
                12.verticalSpace,
                _ProgressStrip(done: done, total: 2),
                26.verticalSpace,
                _SectionCard(
                  title: l10n.roadmapSectionTitle,
                  subtitle: l10n.roadmapSectionSubtitle,
                ),
                20.verticalSpace,
                _RoadmapNode(
                  title: l10n.roadmapReadNode(count: lesson.keypointCount),
                  icon: Icons.menu_book_rounded,
                  tint: const Color(0xFFEEEDFB),
                  iconColor: AppCustomColor.brandPrimary,
                  state: _readDone
                      ? _NodeState.done
                      : (_readStarted ? _NodeState.inProgress : _NodeState.open),
                  hasConnector: true,
                  onTap: onOpenReader,
                ),
                _RoadmapNode(
                  title: l10n.roadmapPracticeNode,
                  icon: Icons.forum_rounded,
                  tint: const Color(0xFFE7F3EE),
                  iconColor: const Color(0xFF3AA07E),
                  state: practiceStarted ? _NodeState.done : _NodeState.open,
                  hasConnector: false,
                  onTap: onOpenPractice,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: floatingNavBarHeight(context) + 24.h,
          child: Center(
            child: _StartCta(
              label: _readStarted ? l10n.roadmapContinueCta : l10n.roadmapStartCta,
              onTap: onOpenReader,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoadmapHeader extends StatelessWidget {
  const _RoadmapHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          label: context.l10n.common.back,
          child: GestureDetector(
            onTap: () {
              AppHaptic.select();
              Navigator.of(context).maybePop();
            },
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22.w,
              color: studyThemeOnBg(context, AppCustomColor.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 120pt bar and its "1/2" — the catalogue roadmap's own header strip,
/// minus the LEVEL label a generated lesson has no levels to fill.
class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: const Color(0xFFE3E8EF),
            borderRadius: BorderRadius.circular(99.r),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: total == 0 ? 0 : (done / total).clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary,
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
          ),
        ),
        10.horizontalSpace,
        AppText(
          '$done/$total',
          style: AppStyle.textBold12.copyWith(
            fontSize: 11.sp,
            letterSpacing: 0.44,
            color: AppCustomColor.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// "FROM YOUR CONTENT" — the one line on this screen that says where the lesson
/// came from, which is the only thing separating it from a catalogue course.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          AppText(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppStyle.textBold14.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.28,
              color: AppCustomColor.textPrimary,
            ),
            maxLines: 2,
          ),
          8.verticalSpace,
          AppText(
            subtitle,
            textAlign: TextAlign.center,
            style: AppStyle.text14.copyWith(
              height: 1.5,
              color: AppCustomColor.textTertiary,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

enum _NodeState { open, inProgress, done }

/// One step: the node marker on the left, the card beside it, and the dashed
/// line down to whatever comes next.
class _RoadmapNode extends StatelessWidget {
  const _RoadmapNode({
    required this.title,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.state,
    required this.hasConnector,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final _NodeState state;
  final bool hasConnector;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 54.w,
            child: Column(
              children: [
                _NodeMarker(state: state),
                if (hasConnector)
                  Expanded(
                    child: Center(
                      child: Container(width: 2.w, color: const Color(0xFFD3D9E4)),
                    ),
                  ),
              ],
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: hasConnector ? 20.h : 0),
              child: _NodeCard(
                title: title,
                icon: icon,
                tint: tint,
                iconColor: iconColor,
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeMarker extends StatelessWidget {
  const _NodeMarker({required this.state});

  final _NodeState state;

  @override
  Widget build(BuildContext context) {
    final done = state == _NodeState.done;
    final started = state == _NodeState.inProgress;

    return Container(
      width: 54.w,
      height: 54.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppCustomColor.brandPrimary : AppCustomColor.backgroundWhite,
        border: Border.all(
          color: done || started
              ? AppCustomColor.brandPrimary
              : AppCustomColor.borderDefault,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: done
          ? Icon(Icons.check_rounded, size: 26.w, color: Colors.white)
          : Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: started
                    ? AppCustomColor.brandPrimary
                    : AppCustomColor.borderDefault,
              ),
            ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.title,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppCustomColor.borderSecondary),
            boxShadow: [
              BoxShadow(
                color: const Color(0x14252525),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 66.w,
                height: 66.w,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 30.w, color: iconColor),
              ),
              13.horizontalSpace,
              Expanded(
                child: AppText(
                  title,
                  style: AppStyle.text14.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: AppCustomColor.textPrimary,
                  ),
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartCta extends StatelessWidget {
  const _StartCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 34.w, vertical: 16.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF554FF0)],
            ),
            borderRadius: BorderRadius.circular(99.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0x66554FF0),
                blurRadius: 30.r,
                offset: Offset(0, 14.h),
              ),
            ],
          ),
          child: AppText(
            label,
            style: AppStyle.textBold16.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
