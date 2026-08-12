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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<UserLessonCubit>().openLesson(widget.lessonId));
    });
  }

  /// Into the deck, at [keypointIndex].
  void _openReader(UserLessonEntity lesson, int keypointIndex) {
    if (lesson.keypoints.isEmpty) return;

    startImportedKeypointLesson(
      lessonCubit: AppDI.injector.get<LessonCubit>(),
      courseLessonCubit: AppDI.injector.get<CourseLessonCubit>(),
      navContext: context,
      userLesson: lesson,
      keypointIndex: keypointIndex.clamp(0, lesson.keypoints.length - 1),
    );
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
                    ? _RoadmapError(
                        message: context.l10n.learningImport.errorGeneric,
                      )
                    : const Center(child: CircularProgressIndicator()),
              );
            }

            return _RoadmapBody(
              lesson: lesson,
              onOpenKeypoint: (index) => _openReader(lesson, index),
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
  const _RoadmapBody({required this.lesson, required this.onOpenKeypoint});

  final UserLessonEntity lesson;
  final ValueChanged<int> onOpenKeypoint;

  /// Where the reader currently stands, as a keypoint index.
  ///
  /// Everything before it is done, it is the one in progress, everything after
  /// is locked -- the catalogue's rule, applied to the only unit a generated
  /// lesson has. `stopAtKeypointIndex` is where opening the lesson resumes, so
  /// it IS that boundary; the section check moves it past the end once the last
  /// card of the last keypoint has been seen.
  int get _currentIndex {
    final keypoints = lesson.keypoints;
    if (keypoints.isEmpty) return 0;

    final last = keypoints.length - 1;
    final finished =
        lesson.stopAtKeypointIndex >= last &&
        lesson.stopAtSectionIndex >= keypoints.last.sections.length - 1;

    return finished ? keypoints.length : lesson.stopAtKeypointIndex;
  }

  bool get _readStarted =>
      lesson.stopAtKeypointIndex > 0 || lesson.stopAtSectionIndex > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;
    final keypoints = lesson.keypoints;
    final current = _currentIndex;

    return Stack(
      children: [
        SafeBody(
          // Header OUTSIDE the scroll, the way the catalogue roadmap builds its
          // own: a back arrow that scrolls away leaves the screen with no
          // navigation at all once you are two nodes down.
          child: Column(
            children: [
              const _RoadmapHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24.w,
                    0,
                    24.w,
                    // Clear of the floating CTA and the nav bar, neither of which is
                    // part of the scroll.
                    floatingNavBarHeight(context) + 120.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _CoverArtwork(),
                      Center(
                        child: AppText(
                          lesson.title,
                          textAlign: TextAlign.center,
                          style: AppStyle.text20.copyWith(
                            fontWeight: FontWeight.w700,
                            color: studyThemeOnBg(
                              context,
                              AppCustomColor.textPrimary,
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ),
                      20.verticalSpace,
                      _ProgressStrip(
                        label: _sourceLabel(context, lesson.sourceType),
                        done: current.clamp(0, keypoints.length),
                        total: keypoints.length,
                      ),
                      26.verticalSpace,
                      _SectionCard(
                        title: l10n.roadmapSectionTitle,
                        subtitle: l10n.roadmapSectionSubtitle(
                          count: keypoints.length,
                        ),
                      ),
                      20.verticalSpace,
                      for (final (index, keypoint) in keypoints.indexed)
                        _RoadmapNode(
                          title: keypoint.title,
                          marker: AppAsset.images.app.roadmapKeypointActive,
                          artwork:
                              kMockUserLessonCovers[index %
                                  kMockUserLessonCovers.length],
                          state: switch (index) {
                            _ when index < current => _NodeState.done,
                            _ when index == current => _NodeState.inProgress,
                            _ => _NodeState.locked,
                          },
                          isFirst: index == 0,
                          isLast: index == keypoints.length - 1,
                          onTap: () => onOpenKeypoint(index),
                        ),
                      // End of the road: the catalogue asks the same question
                      // when a level runs out of content, and a generated lesson
                      // that has been read to the end is in exactly that
                      // position. Only then — see the panel's own doc.
                      if (lesson.isCompleted) ...[
                        8.verticalSpace,
                        UserLessonAdditionalContentPanel(lesson: lesson),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Decorative fade behind the CTA, IgnorePointer so it never blocks a
        // tap on the node beneath. Theme-aware for the reason the catalogue
        // spells out: a solid white slab glares over a custom study background.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 200.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _fadeColor(context).withValues(alpha: 0),
                    _fadeColor(context),
                  ],
                ),
              ),
            ),
          ),
        ),
        // No CTA once the lesson is finished. "Continue" with nothing left to
        // continue is a button that lies; rereading is still one tap away on
        // any node.
        if (!lesson.isCompleted)
          Positioned(
            left: 20.w,
            right: 20.w,
            // The nav bar's ACTUAL height, which varies with the device's
            // safe-area inset, rather than a flat guess.
            bottom: floatingNavBarHeight(context) + 8.h,
            child: Center(
              child: _StartCta(
                label: _readStarted
                    ? l10n.roadmapContinueCta
                    : l10n.roadmapStartCta,
                // Resumes where they stopped, which is the node drawn as
                // current.
                onTap: () => onOpenKeypoint(
                  current.clamp(0, (keypoints.length - 1).clamp(0, 1 << 30)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// End colour of the bottom CTA fade: solid white on the stock background, a
/// theme-aware scrim over a custom one. Mirrors `_roadmapFadeColor` in
/// `course_roadmap_page`.
Color _fadeColor(BuildContext context) {
  if (!studyThemeHasCustomBg(context)) return AppCustomColor.backgroundWhite;

  return studyThemeIsDarkBg(context)
      ? const Color(0xB3000000)
      : AppCustomColor.backgroundWhite.op(0.65);
}

/// Where the material came from, for the strip's left slot. Not localised on
/// purpose — "YouTube" and "PDF" are the same word everywhere MeUp ships.
String _sourceLabel(BuildContext context, ImportSourceTypeEntity source) {
  return switch (source) {
    ImportSourceTypeEntity.youtube => 'YOUTUBE',
    ImportSourceTypeEntity.pdf => 'PDF',
    _ => context.l10n.learningImport.roadmapSectionTitle.toUpperCase(),
  };
}

class _RoadmapHeader extends StatelessWidget {
  const _RoadmapHeader();

  @override
  Widget build(BuildContext context) {
    // Same two affordances, same insets, as the catalogue roadmap's header:
    // back on the left, change-background on the right. Two roadmaps that sit
    // one tap apart should not be arranged differently.
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            button: true,
            label: context.l10n.common.back,
            child: IconButton(
              key: const Key('user-lesson-roadmap-back'),
              padding: EdgeInsets.only(left: 12.w),
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20.w,
                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
              ),
              // No route-name assert on the way out. This screen is arrived at
              // from four places, so the page underneath is My Creations only
              // sometimes (Profile when a popup/toast opened it, an Explore page
              // when the import screen did) — naming it My Creations was a guess
              // that was wrong more often than right. The pop's own `didPop`
              // reports the real page underneath a moment later either way; see
              // `user_lesson_roadmap_nav_test.dart`, which pins that for all
              // four entry paths.
              onPressed: () {
                AppHaptic.select();
                Navigator.of(context).maybePop();
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: const ChangeBackgroundButton(
              key: Key('user-lesson-roadmap-change-theme'),
              size: 40,
              source: 'user_lesson_roadmap',
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverArtwork extends StatelessWidget {
  const _CoverArtwork();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120.w,
        height: 120.w,
        margin: EdgeInsets.only(bottom: 24.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F0FD),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(color: AppCustomColor.borderDefault, blurRadius: 28.r),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(kMockUserLessonCourseCover, fit: BoxFit.cover),
      ),
    );
  }
}

/// Source label, bar, count — the catalogue roadmap's header strip, with the
/// LEVEL slot filled by where the material came from. A generated lesson has no
/// levels, but it does have a provenance, and that is the one fact about it the
/// catalogue's courses cannot state.
class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.label,
    required this.done,
    required this.total,
  });

  final String label;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final muted = studyThemeOnBg(context, AppCustomColor.textTertiary);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Row(
        children: [
          AppText(
            label,
            style: AppStyle.textBold10.copyWith(color: muted),
            maxLines: 1,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            width: 4.w,
            height: 4.w,
            decoration: const ShapeDecoration(
              color: Color(0xFFAAB7CC),
              shape: OvalBorder(),
            ),
          ),
          Expanded(
            child: Container(
              height: 9.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E8EF),
                borderRadius: BorderRadius.circular(18.r),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: total == 0 ? 0 : (done / total).clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B44CA),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
              ),
            ),
          ),
          12.horizontalSpace,
          AppText(
            context.l10n.learningImport
                .roadmapStepsProgress(completed: done, total: total)
                .toUpperCase(),
            style: AppStyle.textBold10.copyWith(color: muted),
            maxLines: 1,
          ),
        ],
      ),
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

enum _NodeState { inProgress, done, locked }

/// One step, drawn the way the catalogue roadmap draws one.
///
/// Every number here is copied from `RoadmapNodeIndicator`, `LessonKeypointCard`
/// and `RoadmapNodeTimeline` rather than eyeballed from the comp: 54pt marker
/// with a 2pt state border, 88pt thumbnail at radius 15, 4pt card padding at
/// radius 16, the same dashed 2pt connector in `borderSecondary`. A lesson the
/// reader made should look like a lesson, and "looks about right" is what makes
/// two screens in the same app feel like two apps.
class _RoadmapNode extends StatelessWidget {
  const _RoadmapNode({
    required this.title,
    required this.marker,
    required this.artwork,
    required this.state,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final String title;

  /// The glyph inside the marker circle — the catalogue's own roadmap icons.
  final AssetGenImage marker;

  /// **MOCK** — see [mockUserLessonCover]. The catalogue puts the lesson's real
  /// cover here; a generated lesson has none.
  final String artwork;

  final _NodeState state;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const dashed = LineStyle(
      color: AppCustomColor.borderSecondary,
      thickness: 2,
      dashLength: 4,
      dashSpacing: 2,
      isDashed: true,
    );

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      alignment: TimelineAlign.start,
      indicatorStyle: IndicatorStyle(
        width: 54.w,
        height: 54.w,
        padding: EdgeInsets.zero,
        indicator: _NodeMarker(state: state, marker: marker),
      ),
      beforeLineStyle: dashed,
      afterLineStyle: dashed,
      endChild: Padding(
        padding: EdgeInsets.only(left: 16.w, top: 10.h, bottom: 10.h),
        child: _NodeCard(
          title: title,
          artwork: artwork,
          state: state,
          // A locked step is not tappable, the same way a locked lesson is not.
          // Greying it and then opening it anyway would teach the reader that
          // the lock means nothing.
          onTap: state == _NodeState.locked ? null : onTap,
        ),
      ),
    );
  }
}

/// The glyph disc and its state ring, with a lock pinned to it when the step is
/// not reachable yet.
class _NodeMarker extends StatelessWidget {
  const _NodeMarker({required this.state, required this.marker});

  final _NodeState state;
  final AssetGenImage marker;

  Color get _borderColor => switch (state) {
    _NodeState.inProgress => AppCustomColor.borderBrand,
    _NodeState.done => AppCustomColor.brandPrimary50,
    _NodeState.locked => AppCustomColor.neutral100,
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 54.w,
          height: 54.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _borderColor, width: 2.w),
          ),
          child: marker.image(fit: BoxFit.contain),
        ),
        if (state == _NodeState.locked)
          Container(
            width: 22.w,
            height: 22.w,
            padding: EdgeInsets.all(5.w),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: AppCustomColor.neutral100,
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: Image.asset(AppAsset.icons.common.lock.path),
          ),
      ],
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.title,
    required this.artwork,
    required this.state,
    required this.onTap,
  });

  final String title;
  final String artwork;
  final _NodeState state;
  final VoidCallback? onTap;

  /// Grayscale, lifted verbatim from `_RoadmapCardThumbnail` so a locked step
  /// here and a locked lesson there fade by exactly the same amount.
  static const _grayscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final isLocked = state == _NodeState.locked;
    final isActive = state == _NodeState.inProgress;

    return Semantics(
      button: true,
      enabled: !isLocked,
      label: title,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                AppHaptic.select();
                onTap!();
              },
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isLocked
                ? AppCustomColor.backgroundGray
                : studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(16.r),
            border: isLocked
                ? null
                : Border.all(
                    color: isActive
                        ? AppCustomColor.brandPrimary
                        : AppCustomColor.neutral300,
                    width: isActive ? 2.w : 1.w,
                  ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child: SizedBox(
                  width: 88.w,
                  height: 88.w,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColorFiltered(
                        colorFilter: isLocked
                            ? _grayscale
                            : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.color,
                              ),
                        child: Image.asset(artwork, fit: BoxFit.cover),
                      ),
                      if (isLocked)
                        Center(
                          child: Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: const BoxDecoration(
                              color: AppCustomColor.neutral100,
                              shape: BoxShape.circle,
                            ),
                            child: Semantics(
                              label: context
                                  .l10n
                                  .courseroadmap
                                  .lockedSemanticLabel,
                              child: Icon(
                                Icons.lock_rounded,
                                color: AppCustomColor.textTertiary,
                                size: 14.w,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: AppText(
                    title,
                    style: AppStyle.text14.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: isLocked
                          ? AppCustomColor.textTertiary
                          : AppCustomColor.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _StartCta extends StatelessWidget {
  const _StartCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // `CourseRoadmapFloatingButton` itself cannot be reused — it reads its label
    // off CourseRoadmapCubit and WarmUpCubit, neither of which this route
    // provides — so this is its body, verbatim.
    return Semantics(
      button: true,
      label: label,
      child: AppButton.primary(
        key: const Key('user-lesson-roadmap-floating-button'),
        onPressed: () {
          AppHaptic.select();
          onTap();
        },
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        borderRadius: BorderRadius.circular(1000.r),
        child: AppText(
          label,
          style: AppStyle.textBold16.copyWith(
            color: AppCustomColor.textWhite,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}
