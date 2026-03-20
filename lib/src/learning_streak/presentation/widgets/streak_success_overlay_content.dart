part of '../../learning_streak.dart';

enum LearningStreakSuccessVariant { p1, p2 }

class LearningStreakSuccessOverlay {
  const LearningStreakSuccessOverlay._();

  static Future<bool> show(
    BuildContext context, {
    required UserLearningStreakEntity streak,
  }) async {
    final variant = streak.currentStreak <= 1 ? LearningStreakSuccessVariant.p1 : LearningStreakSuccessVariant.p2;
    var hasHandledCommit = false;
    AppService.instance.appTrackingService.trackCompletionStreakSuccessView(
      variant: variant.name,
      currentStreak: streak.currentStreak,
    );

    final committed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'learningStreakSuccess',
      barrierColor: AppCustomColor.scrimOverlay,
      useRootNavigator: false,
      routeSettings: const RouteSettings(name: 'Learning Streak Success'),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, _) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: PopScope(
              canPop: false,
              child: StreakSuccessOverlayContent(
                streak: streak,
                variant: variant,
                onCommit: () {
                  if (hasHandledCommit) return;
                  hasHandledCommit = true;
                  AppService.instance.appTrackingService.trackCompletionStreakSuccessCommitClick(
                    variant: variant.name,
                    currentStreak: streak.currentStreak,
                  );
                  context.pop(true);
                },
              ),
            ),
          ),
        );
      },
    );

    return committed ?? false;
  }
}

class StreakSuccessOverlayContent extends StatelessWidget {
  const StreakSuccessOverlayContent({
    super.key,
    required this.streak,
    required this.variant,
    required this.onCommit,
  });

  final UserLearningStreakEntity streak;
  final LearningStreakSuccessVariant variant;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppCustomColor.backgroundBrandSoft,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            children: [
              const Spacer(),
              Column(
                children: [
                  SizedBox(
                    width: 120.r,
                    height: 120.r,
                    child: Lottie.asset(
                      AppAsset.lottie.flame,
                      fit: BoxFit.contain,
                    ),
                  ),
                  AppText(
                    variant == LearningStreakSuccessVariant.p1 ? context.l10n.learningStreak.startedTitle : context.l10n.learningStreak.streakDays(count: streak.currentStreak),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppStyle.textBold24.copyWith(color: AppCustomColor.textBrand),
                  ),
                  AppText(
                    context.l10n.learningStreak.successSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.streakTextMuted,
                      fontWeight: FontWeight.w500,
                      height: 1.75,
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20.h),
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppCustomColor.borderDefault, width: 2),
                ),
                child: StreakWeekBar(weekStudy: streak.normalizedWeekStudy),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onCommit,
                child: Container(
                  height: 54.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppCustomColor.brandPrimary,
                    borderRadius: BorderRadius.circular(1000.r),
                  ),
                  alignment: Alignment.center,
                  child: AppText(
                    context.l10n.learningStreak.commitButton,
                    style: AppStyle.textBold16.copyWith(
                      color: AppCustomColor.textWhite,
                      height: 1.5,
                    ),
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
