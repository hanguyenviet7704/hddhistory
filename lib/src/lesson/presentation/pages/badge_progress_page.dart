part of '../../lesson.dart';

enum BadgeProgressStep { inProgress, complete }

class BadgeProgressPage extends StatefulWidget {
  const BadgeProgressPage({super.key});

  @override
  State<BadgeProgressPage> createState() => _BadgeProgressPageState();
}

class _BadgeProgressPageState extends State<BadgeProgressPage> {
  static const Duration _autoAdvanceDelay = Duration(seconds: 3);

  BadgeProgressStep _step = BadgeProgressStep.inProgress;
  Timer? _autoAdvanceTimer;
  bool _hasExited = false;
  bool _hasTrackedBadgeUpdate = false;
  bool _hasTrackedComplete = false;

  @override
  void initState() {
    super.initState();
    _scheduleAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(_autoAdvanceDelay, _handleAdvance);
  }

  bool _isProgressComplete(CourseLevelProgressEntity progress) {
    return progress.isCompleted || progress.progress >= 1;
  }

  void _handleAdvance() {
    if (_hasExited || !mounted) return;
    final progress = context.read<CourseRoadmapCubit>().state.currentLevelProgress;

    if (_step == BadgeProgressStep.inProgress) {
      if (_isProgressComplete(progress)) {
        _switchToComplete();
        return;
      }
      _exitToRoadmap();
      return;
    }

    _exitToRoadmap();
  }

  void _switchToComplete() {
    if (!mounted) return;
    setState(() => _step = BadgeProgressStep.complete);
    _scheduleAutoAdvance();
  }

  void _exitToRoadmap() {
    if (_hasExited) return;
    _hasExited = true;
    if (!mounted) return;

    final courseLessonState = AppDI.injector.get<CourseLessonCubit>().state;
    final homeState = AppDI.injector.get<HomeCubit>().state;
    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final courseId = resolveLessonFlowCourseId(
      lessonCourseId: courseLessonState.selectedLesson.courseId,
      roadmapCourseId: roadmapState.roadmap.courseId,
      homeCourseId: homeState.currentCourse.id,
    );
    syncHomeSelectionForLessonFlowCourse(courseId);

    CourseRoadmapRoute().go(context);
  }

  void _trackCompleteView() {
    if (_hasTrackedComplete) return;
    final trackingData = RoleplayTrackingData.fromContext();
    AppService.instance.appTrackingService.trackBadgeCompleteScrView(trackingData: trackingData);
    _hasTrackedComplete = true;
  }

  void _trackBadgeUpdateScrView() {
    if (_hasTrackedBadgeUpdate) return;
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackKeypointBadgeUpdateScrView(trackingData);
    _hasTrackedBadgeUpdate = true;
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = context.select((CourseLessonCubit cubit) => cubit.state.currentTitle);

    return BlocListener<CourseRoadmapCubit, CourseRoadmapState>(
      listenWhen: (previous, current) =>
          previous.currentLevelProgress.progress != current.currentLevelProgress.progress || previous.currentLevelProgress.isCompleted != current.currentLevelProgress.isCompleted,
      listener: (context, state) {
        if (_step != BadgeProgressStep.inProgress) return;
        if (_isProgressComplete(state.currentLevelProgress)) {
          _switchToComplete();
        }
      },
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundWhite,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleAdvance,
            child: Stack(
              children: [
                if (_step == BadgeProgressStep.complete) ...[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Lottie.asset(
                        AppAsset.lottie.congratulations,
                        fit: BoxFit.cover,
                        repeat: false,
                      ),
                    ),
                  ),
                ],
                Positioned.fill(
                  child: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, CourseLevelProgressEntity>(
                    selector: (state) => state.currentLevelProgress,
                    builder: (context, progress) {
                      if (_step == BadgeProgressStep.inProgress) {
                        _trackBadgeUpdateScrView();
                      }
                      if (_step == BadgeProgressStep.complete) {
                        _trackCompleteView();
                      }
                      return _BadgeProgressContent(
                        progress: progress,
                        step: _step,
                        currentTitle: currentTitle,
                        onPrimaryCta: _handleAdvance,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeProgressContent extends StatelessWidget {
  final CourseLevelProgressEntity progress;
  final BadgeProgressStep step;
  final String currentTitle;
  final VoidCallback onPrimaryCta;

  const _BadgeProgressContent({
    required this.progress,
    required this.step,
    required this.currentTitle,
    required this.onPrimaryCta,
  });

  bool get _isInProgress => step == BadgeProgressStep.inProgress;

  String get _badgeUrl {
    if (_isInProgress) {
      return progress.darkBadge.trim();
    }
    return progress.lightBadge.trim();
  }

  int get _lessonsLeft => (progress.totalKeypoints - progress.completedKeypoints).clamp(0, progress.totalKeypoints);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: _LessonCompleteBanner(
            subtitle: _isInProgress ? currentTitle : progress.title,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BadgeProgressBadge(url: _badgeUrl),
                24.verticalSpace,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      context.l10n.exercise.exerciseBadgeCompleteLabel.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppStyle.text12.copyWith(
                        color: AppCustomColor.textTertiary,
                        fontWeight: FontWeight.w600,
                        height: 1.75,
                      ),
                    ),
                    4.verticalSpace,
                    AppText(
                      progress.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppStyle.text20.copyWith(
                        color: AppCustomColor.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                if (_isInProgress) ...[
                  12.verticalSpace,
                  _BadgeProgressBar(progress: progress.progress),
                  4.verticalSpace,
                  AppText(
                    context.l10n.exercise.exerciseProgressCompletedPercent(percent: progress.progressPercent),
                    textAlign: TextAlign.center,
                    style: AppStyle.text10.copyWith(
                      color: AppCustomColor.brandPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.75,
                    ),
                  ),
                ] else ...[
                  12.verticalSpace,
                  AppText(
                    context.l10n.exercise.exerciseBadgeCompleteMessage,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppStyle.text16.copyWith(
                      color: AppCustomColor.textTertiary,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isInProgress && _lessonsLeft > 0) ...[
          _LessonsLeftTooltip(count: _lessonsLeft),
          16.verticalSpace,
        ],
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: DButton(
            text: _isInProgress ? context.l10n.exercise.exerciseCompleteKeypointSkipButton : context.l10n.exercise.exerciseCompleteLessonButton,
            size: Size(double.infinity, 54.h),
            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
            onPressed: onPrimaryCta,
          ),
        ),
      ],
    );
  }
}

/// The "LESSON COMPLETE!" bordered banner shown at the top of both badge
/// progress steps (Figma 10326:49600 / 10326:49618). Subtitle is the just-
/// finished keypoint's title while progress is ongoing, or the badge's own
/// title once it's fully unlocked (there's no longer a "current" keypoint).
///
/// Per the Figma annotation ("Success Toast: Slide in, stay visible for 3s")
/// this isn't static — it slides down into view, holds for 3s, then slides
/// back out and collapses so the badge content below re-centers.
class _LessonCompleteBanner extends StatefulWidget {
  final String subtitle;

  const _LessonCompleteBanner({required this.subtitle});

  @override
  State<_LessonCompleteBanner> createState() => _LessonCompleteBannerState();
}

class _LessonCompleteBannerState extends State<_LessonCompleteBanner> {
  static const _visibleDuration = Duration(seconds: 3);
  static const _transitionDuration = Duration(milliseconds: 300);

  bool _visible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
    });
    _hideTimer = Timer(_visibleDuration + _transitionDuration, () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: _transitionDuration,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSlide(
        duration: _transitionDuration,
        curve: Curves.easeOut,
        offset: _visible ? Offset.zero : const Offset(0, -1),
        child: AnimatedOpacity(
          duration: _transitionDuration,
          opacity: _visible ? 1 : 0,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              border: Border.all(color: AppCustomColor.borderSecondary, width: 2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  context.l10n.exercise.exerciseLessonCompleteTitle.toUpperCase(),
                  style: AppStyle.text12.copyWith(color: AppCustomColor.streakActive, fontWeight: FontWeight.w700),
                ),
                4.verticalSpace,
                AppText(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Always-visible speech-bubble tooltip above the CTA (Figma 10326:49607,
/// annotated "Tooltip: always visible") — nudges the user with how many more
/// lessons unlock the badge. Hidden once there's nothing left to nudge about.
class _LessonsLeftTooltip extends StatelessWidget {
  final int count;

  const _LessonsLeftTooltip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppCustomColor.brandPrimary700,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: AppText(
              context.l10n.exercise.exerciseLessonsLeftToUnlock(count: count),
              style: AppStyle.text14.copyWith(color: AppCustomColor.textWhite, fontWeight: FontWeight.w700),
            ),
          ),
          Positioned(
            bottom: -6.w,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 12.w,
                height: 12.w,
                color: AppCustomColor.brandPrimary700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeProgressBadge extends StatelessWidget {
  const _BadgeProgressBadge({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const double badgeWidth = 118.5;
    const double badgeHeight = 150;

    if (url.isEmpty) {
      return Container(
        width: badgeWidth.w,
        height: badgeHeight.h,
        decoration: BoxDecoration(
          color: AppCustomColor.borderSecondary,
          borderRadius: BorderRadius.circular(16.r),
        ),
      );
    }

    return CacheNetworkGraphic(
      url: url,
      width: badgeWidth.w,
      height: badgeHeight.h,
      fit: BoxFit.contain,
    );
  }
}

class _BadgeProgressBar extends StatelessWidget {
  final double progress;

  const _BadgeProgressBar({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140.w,
      child: LinearPercentIndicator(
        lineHeight: 8.h,
        percent: progress.clamp(0.0, 1.0),
        animation: true,
        animationDuration: 800,
        animateFromLastPercent: true,
        padding: EdgeInsets.zero,
        backgroundColor: AppCustomColor.borderSecondary,
        progressColor: AppCustomColor.brandPrimary,
        barRadius: Radius.circular(18.r),
      ),
    );
  }
}
