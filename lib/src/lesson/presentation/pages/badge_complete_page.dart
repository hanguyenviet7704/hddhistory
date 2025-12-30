part of '../../lesson.dart';

class BadgeCompletePage extends StatefulWidget {
  const BadgeCompletePage({super.key});

  @override
  State<BadgeCompletePage> createState() => _BadgeCompletePageState();
}

class _BadgeCompletePageState extends State<BadgeCompletePage> {
  static const Duration _autoCloseDelay = Duration(seconds: 3);
  Timer? _autoCloseTimer;
  bool _hasExited = false;

  @override
  void initState() {
    super.initState();
    _autoCloseTimer = Timer(_autoCloseDelay, _handleExit);
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _handleExit() {
    if (_hasExited) return;
    _hasExited = true;
    if (!mounted) return;
    context.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleExit,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Lottie.asset(
                    AppAsset.lottie.congratulations,
                    fit: BoxFit.cover,
                    repeat: false,
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, CourseLevelProgressEntity>(
                        selector: (state) => state.currentLevelProgress,
                        builder: (context, progress) {
                          final String badgeUrl = progress.badgeUrl;
                          final String title = progress.title;
                          final double badgeWidth = 118.5.w;
                          final double badgeHeight = 150.h;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: double.infinity),
                              if (badgeUrl.isEmpty)
                                Container(
                                  width: badgeWidth,
                                  height: badgeHeight,
                                  decoration: BoxDecoration(
                                    color: AppCustomColor.borderSecondary,
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                )
                              else
                                CacheNetworkGraphic(
                                  url: badgeUrl,
                                  width: badgeWidth,
                                  height: badgeHeight,
                                  fit: BoxFit.contain,
                                ),
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
                                    title,
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
                              24.verticalSpace,
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
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
