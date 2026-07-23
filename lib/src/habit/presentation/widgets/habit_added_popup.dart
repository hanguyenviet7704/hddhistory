part of '../../habit.dart';

// Figma 10788:52956 "Bullseye" — pulled from the design file.
const String _kHabitAddedPlant = 'assets/svg/common/habit_added_plant.svg';

/// Success popup shown right after adopting ("Habit added!", design.md 5.2) or
/// upgrading ("Habit upgraded!", flowchart) a habit. "Go to Habit" routes to
/// the Habit tab (pops `true`); "Continue" just dismisses (pops `false`) and
/// lets the caller keep going (e.g. resume the lesson flow).
class HabitAddedPopup extends StatelessWidget {
  final String title;
  final String subtitle;
  // The "Habit upgraded!" variant reuses this popup; its view/CTA taps are NOT
  // part of the habit_added_* funnel, so tracking is suppressed when true.
  final bool isUpgraded;

  const HabitAddedPopup({super.key, required this.title, required this.subtitle, this.isUpgraded = false});

  static Future<bool?> show(BuildContext context, {String? title, String? subtitle, bool isUpgraded = false}) {
    final resolvedTitle = title ?? context.l10n.habit.adoptAddedTitle;
    final resolvedSubtitle = subtitle ?? context.l10n.habit.adoptAddedSubtitle;
    if (!isUpgraded) HabitTracking.addedScrView();
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'habitAddedPopup',
      barrierColor: AppCustomColor.scrimOverlay,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, _) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: HabitAddedPopup(title: resolvedTitle, subtitle: resolvedSubtitle, isUpgraded: isUpgraded),
          ),
        );
      },
    );
  }

  /// Convenience for the post-upgrade success popup (flowchart "Habit upgraded!").
  static Future<bool?> showUpgraded(BuildContext context) => show(
    context,
    title: context.l10n.habit.upgradedTitle,
    subtitle: context.l10n.habit.upgradedSubtitle,
    isUpgraded: true,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 40.w),
                  padding: EdgeInsets.fromLTRB(20.w, 52.h, 20.w, 20.h),
                  decoration: BoxDecoration(
                    color: AppCustomColor.backgroundWhite,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        title,
                        textAlign: TextAlign.center,
                        style: AppStyle.text22.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
                      ),
                      4.verticalSpace,
                      AppText(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppStyle.text13.copyWith(color: AppCustomColor.textSecondary),
                      ),
                      24.verticalSpace,
                      Row(
                        children: [
                          Expanded(
                            child: DButton(
                              text: context.l10n.habit.adoptGoToHabitButton,
                              backgroundColor: AppCustomColor.brandPrimary50,
                              size: Size(double.infinity, 54.h),
                              style: AppStyle.textBold16.copyWith(color: AppCustomColor.streakActive),
                              onPressed: () {
                                if (!isUpgraded) HabitTracking.addedGoHabit();
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ),
                          8.horizontalSpace,
                          Expanded(
                            child: DButton(
                              text: context.l10n.common.kContinue,
                              backgroundColor: AppCustomColor.brandPrimary,
                              size: Size(double.infinity, 54.h),
                              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
                              onPressed: () {
                                if (!isUpgraded) HabitTracking.addedContinue();
                                Navigator.of(context).pop(false);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(_kHabitAddedPlant, width: 90.w, height: 90.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
