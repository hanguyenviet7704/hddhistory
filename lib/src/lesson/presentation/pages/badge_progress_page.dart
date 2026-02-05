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
    CourseRoadmapRoute().go(context);
  }

  void _trackCompleteView() {
    if (_hasTrackedComplete) return;
    final trackingData = RoleplayTrackingData.fromContext();
    AppService.instance.appTrackingService.trackBadgeCompleteScrView(trackingData: trackingData);
    _hasTrackedComplete = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseRoadmapCubit, CourseRoadmapState>(
      listenWhen: (previous, current) =>
          previous.currentLevelProgress.progress != current.currentLevelProgress.progress ||
          previous.currentLevelProgress.isCompleted != current.currentLevelProgress.isCompleted,
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
                      if (_step == BadgeProgressStep.complete) {
                        _trackCompleteView();
                      }
                      return _BadgeProgressContent(
                        progress: progress,
                        step: _step,
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

  const _BadgeProgressContent({
    required this.progress,
    required this.step,
  });

  String get _badgeUrl {
    if (step == BadgeProgressStep.inProgress) {
      return progress.darkBadge.trim();
    }
    return progress.lightBadge.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                context.text.exercise.exerciseBadgeCompleteLabel.toUpperCase(),
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
          if (step == BadgeProgressStep.inProgress) ...[
            12.verticalSpace,
            _BadgeProgressBar(progress: progress.progress),
            4.verticalSpace,
            AppText(
              context.text.exercise.exerciseProgressCompletedPercent(percent: progress.progressPercent),
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
              context.text.exercise.exerciseBadgeCompleteMessage,
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
