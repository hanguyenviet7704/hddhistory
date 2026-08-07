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
                            // Design: a WHITE pill, the green lives in the glyph
                            // and text.
                            decoration: BoxDecoration(
                              color: AppCustomColor.backgroundWhite,
                              borderRadius: BorderRadius.circular(99.r),
                              boxShadow: [BoxShadow(color: const Color(0x0F141828), blurRadius: 10, offset: const Offset(0, 3))],
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
                // Design: the pill is content-width centred (~254/390), not a
                // screen-wide bar.
                Center(
                  child: Semantics(
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
                          width: 254.w,
                          height: 52.h,
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

  /// The design's own plant-pot illustration (`assets/illus-plant-pot.svg` in
  /// the MeUp design project, copied verbatim) — sprout, purple pot, and the
  /// green/white sparkles are all IN the art, so nothing is overlaid here.
  Widget _plant() {
    return SvgPicture.asset('assets/svg/common/habit_practice_plant.svg', width: 150.w);
  }
}
