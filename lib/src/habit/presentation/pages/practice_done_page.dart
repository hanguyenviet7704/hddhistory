part of '../../habit.dart';

/// "Practice complete" (design "5 · Habit" → 3 · Practice complete): the
/// habit-as-plant payoff screen. A speech bubble ("Repeat it enough, it
/// becomes everyday life") floats over the potted-plant illustration,
/// "Habit is growing!" underneath, then the streak as an "∞ N days loop"
/// chip, and a full-width "Back to habit" pill at the bottom.
///
/// Shown after the attempt has already been submitted, so it reports rather
/// than writes — there is no retry here, and closing it cannot lose the
/// check-in. The streak is read from [HabitCubit]'s CURRENT state rather than
/// the passed-in row: the check-in that just happened bumped it, and the
/// caller's copy may predate that write.
class PracticeDonePage extends StatelessWidget {
  final UserHabitEntity userHabit;

  const PracticeDonePage({super.key, required this.userHabit});

  static Future<void> push(BuildContext context, {required UserHabitEntity userHabit}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PracticeDonePage(userHabit: userHabit)),
    );
  }

  int _currentStreak() {
    final fresh = AppDI.injector.get<HabitCubit>().state.userHabits.where((row) => row.id == userHabit.id).firstOrNull;
    return (fresh ?? userHabit).currentStreak;
  }

  @override
  Widget build(BuildContext context) {
    final streak = _currentStreak();

    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundBrandSoft),
      body: ThemedBackground(
        child: SafePage(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _speechBubble(context),
                        14.verticalSpace,
                        _plant(),
                        26.verticalSpace,
                        AppText(
                          context.l10n.habit.practiceGrowTitle,
                          textAlign: TextAlign.center,
                          // Design 26/800.
                          style: TextStyle(
                            fontFamily: AppFont.mulish,
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                          ),
                        ),
                        if (streak > 0) ...[
                          12.verticalSpace,
                          Container(
                            height: 28.h,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: AppCustomColor.kpResultCorrectSurface,
                              borderRadius: BorderRadius.circular(99.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.all_inclusive_rounded, size: 14.w, color: AppCustomColor.successGreen),
                                6.horizontalSpace,
                                AppText(
                                  context.l10n.habit.practiceGrowLoop(days: '$streak'),
                                  style: AppStyle.text12.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppCustomColor.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  child: Material(
                    color: AppCustomColor.brandPrimary,
                    borderRadius: BorderRadius.circular(999.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999.r),
                      onTap: () {
                        AppHaptic.select();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 54.h,
                        alignment: Alignment.center,
                        child: AppText(
                          context.l10n.habit.practiceDoneButton,
                          style: AppStyle.text16.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppCustomColor.textWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The design's caption bubble above the plant — white rounded card with a
  /// small diamond tail pointing down at the sprout.
  Widget _speechBubble(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: 210.w),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: const Color(0x14141828), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: AppText(
            context.l10n.habit.practiceGrowBubble,
            textAlign: TextAlign.center,
            maxLines: 2,
            // Design ~11.5/600.
            style: TextStyle(
              fontFamily: AppFont.mulish,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppCustomColor.textPrimary,
            ),
          ),
        ),
        // Tail: a rotated square tucked under the bubble.
        Transform.translate(
          offset: Offset(0, -4.h),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 9.w, height: 9.w, color: AppCustomColor.backgroundWhite),
          ),
        ),
      ],
    );
  }

  /// The potted plant with the design's little sparkles. The pot art is the
  /// existing habit motif asset, so this screen and the reminders share one
  /// plant.
  Widget _plant() {
    return SizedBox(
      width: 170.w,
      height: 150.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(AppAsset.svg.common.habitReminderPlant, width: 112.w),
          Positioned(
            left: 18.w,
            top: 26.h,
            child: Icon(Icons.auto_awesome, size: 16.w, color: AppCustomColor.successGreen.withValues(alpha: 0.75)),
          ),
          Positioned(
            right: 22.w,
            bottom: 34.h,
            child: Icon(Icons.auto_awesome, size: 11.w, color: AppCustomColor.successGreen.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}
