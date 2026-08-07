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
class PracticeDonePage extends StatefulWidget {
  final UserHabitEntity userHabit;

  const PracticeDonePage({super.key, required this.userHabit});

  /// A payoff screen fades IN over where the reader already is — the default
  /// right-to-left push read as navigating somewhere else, not as a reward
  /// appearing.
  static Future<void> push(BuildContext context, {required UserHabitEntity userHabit}) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => PracticeDonePage(userHabit: userHabit),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }

  @override
  State<PracticeDonePage> createState() => _PracticeDonePageState();
}

class _PracticeDonePageState extends State<PracticeDonePage> with TickerProviderStateMixin {
  /// One clock for the staged entrance; element delays are [Interval]s on it —
  /// same pattern as the lesson-complete illustration.
  static const _introMs = 900;
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: _introMs))..forward();

  /// Gentle ±3px bob of the plant group, forever.
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

  Animation<double> _stage(int delayMs, int durationMs, [Curve curve = Curves.easeOut]) {
    return CurvedAnimation(parent: _intro, curve: Interval(delayMs / _introMs, (delayMs + durationMs) / _introMs, curve: curve));
  }

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    super.dispose();
  }

  /// Fade in while drifting up into place.
  Widget _rise(Animation<double> t, Widget child) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(opacity: t.value.clamp(0, 1), child: Transform.translate(offset: Offset(0, 14 * (1 - t.value)), child: child)),
      child: child,
    );
  }

  /// Scale in with an overshoot — the plant "grows" into place.
  Widget _pop(Animation<double> t, Widget child) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(opacity: t.value.clamp(0, 1), child: Transform.scale(scale: 0.6 + 0.4 * t.value, child: child)),
      child: child,
    );
  }

  int _currentStreak() {
    final fresh = AppDI.injector.get<HabitCubit>().state.userHabits.where((row) => row.id == widget.userHabit.id).firstOrNull;
    return (fresh ?? widget.userHabit).currentStreak;
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
                        // The plant grows in first, the bubble comments on it,
                        // then the words land — with the whole plant group
                        // bobbing gently once it is up.
                        AnimatedBuilder(
                          animation: _float,
                          builder: (context, child) => Transform.translate(offset: Offset(0, -3.h * _float.value), child: child),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _rise(_stage(250, 400), _speechBubble(context)),
                              14.verticalSpace,
                              _pop(_stage(0, 500, Curves.easeOutBack), _plant()),
                            ],
                          ),
                        ),
                        26.verticalSpace,
                        _rise(
                          _stage(380, 400),
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
                        ),
                        if (streak > 0) ...[
                          12.verticalSpace,
                          _rise(
                            _stage(520, 380),
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
