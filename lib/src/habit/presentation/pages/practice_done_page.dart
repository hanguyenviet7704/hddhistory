part of '../../habit.dart';

/// "Practice complete" (design "5 · Habit" → quizdone / journaldone).
///
/// Shown after the attempt has already been submitted, so it reports rather than
/// writes — there is no retry here, and closing it cannot lose the check-in.
/// [correct] and [total] are omitted for a journal, which has nothing to score.
class PracticeDonePage extends StatelessWidget {
  final UserHabitEntity userHabit;
  final int? correct;
  final int? total;

  const PracticeDonePage({super.key, required this.userHabit, this.correct, this.total});

  static Future<void> push(
    BuildContext context, {
    required UserHabitEntity userHabit,
    int? correct,
    int? total,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PracticeDonePage(userHabit: userHabit, correct: correct, total: total),
      ),
    );
  }

  bool get _hasScore => correct != null && total != null && total! > 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundBrandSoft),
      body: ThemedBackground(
        child: SafePage(
          // In the design this is the LAST CARD of the quiz deck, not a bare
          // screen — so it keeps the deck's card: same inset, same radius, same
          // frosted-over-a-custom-background treatment. On the wallpaper alone
          // the white title and grey subtitle had to compete with the photo.
          //
          // Inside it: a centred stack with a 14 gap, a solid pale-green disc
          // (NOT a 12%-alpha tint — over a photo that washed out to invisible),
          // and a pill sized to its label rather than a screen-wide bar.
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 28.h),
            child: ThemedGlassCard(
              frosted: true,
              radius: 22,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              shadow: [
                BoxShadow(
                  color: AppCustomColor.textPrimary.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 74.w,
                    height: 74.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppCustomColor.kpResultCorrectSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, size: 34.w, color: AppCustomColor.successGreen),
                  ),
                  14.verticalSpace,
                  AppText(
                    context.l10n.habit.practiceDoneTitle,
                    textAlign: TextAlign.center,
                    // Design 21/700.
                    style: AppStyle.text22.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppCustomColor.textPrimary,
                    ),
                  ),
                  14.verticalSpace,
                  AppText(
                    context.l10n.habit.practiceDoneSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: AppStyle.text14.copyWith(
                      height: 1.6,
                      color: AppCustomColor.textTertiary,
                    ),
                  ),
                  if (_hasScore) ...[
                    14.verticalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                      // Brand tint, not white: this now sits ON the white card,
                      // where a white pill would be an invisible chip.
                      decoration: BoxDecoration(
                        color: AppCustomColor.brandPrimary50,
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                      child: AppText(
                        context.l10n.habit.practiceDoneScore(
                          correct: '$correct',
                          total: '$total',
                        ),
                        style: AppStyle.textBold16.copyWith(color: AppCustomColor.brandPrimary),
                      ),
                    ),
                  ],
                  14.verticalSpace,
                  AppText(
                    userHabit.displayTitle,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: AppStyle.text14.copyWith(
                      color: AppCustomColor.textSecondary,
                    ),
                  ),
                  22.verticalSpace,
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
                        // A Row(mainAxisSize.min), not `alignment:` — setting
                        // alignment turns the Container into an Align, which
                        // expands to the incoming width and would stretch this
                        // content-sized pill across the whole screen.
                        child: Container(
                          height: 50.h,
                          padding: EdgeInsets.symmetric(horizontal: 28.w),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppText(
                                context.l10n.habit.practiceDoneButton,
                                style: AppStyle.text16.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppCustomColor.textWhite,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
