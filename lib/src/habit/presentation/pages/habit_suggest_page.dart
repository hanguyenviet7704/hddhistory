part of '../../habit.dart';

/// The recap-flow habit step (design "3 · Learning" → Recap: "Add one to get
/// daily practice reminders"): the lesson's suggested habits as tappable rows,
/// each flipping to an "Added" chip when adopted, and one Continue that always
/// moves the flow on to the lesson-complete screen.
///
/// This SITS BETWEEN the recap flip card and lesson complete — it replaced the
/// old placement where [AdoptHabitPage] popped up after "Skip to next lesson",
/// i.e. after the reader had already said they were leaving. Unlike that page
/// (radio pick + one Add), this one adopts per row: several habits can be
/// added in one visit, and Continue is never blocked on choosing.
class HabitSuggestPage extends StatefulWidget {
  final List<HabitEntity> habits;
  final String? sourceKeypointId;
  final String? sourceCourseId;

  const HabitSuggestPage({
    super.key,
    required this.habits,
    this.sourceKeypointId,
    this.sourceCourseId,
  });

  /// Pushed on the ROOT navigator so it overlays the shell (and its floating
  /// nav) exactly like [AdoptHabitPage] did. Resolves when the reader
  /// continues.
  static Future<void> push(
    BuildContext context, {
    required List<HabitEntity> habits,
    String? sourceKeypointId,
    String? sourceCourseId,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: AppDI.injector.get<HabitCubit>(),
          child: HabitSuggestPage(
            habits: habits,
            sourceKeypointId: sourceKeypointId,
            sourceCourseId: sourceCourseId,
          ),
        ),
      ),
    );
  }

  @override
  State<HabitSuggestPage> createState() => _HabitSuggestPageState();
}

class _HabitSuggestPageState extends State<HabitSuggestPage> {
  static const int _defaultPackLength = 3;

  /// Habit id currently mid-write (adopt OR check-in) — its row shows a
  /// spinner chip and every other row ignores taps, so two quick taps can't
  /// fire two writes.
  String? _submittingHabitId;

  UserHabitEntity? _adoptedRowFor(HabitEntity habit) {
    for (final userHabit in context.read<HabitCubit>().state.userHabits) {
      if (userHabit.habitId == habit.id) return userHabit;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureNavHidden();
      HabitTracking.startScrView(courseId: widget.sourceCourseId);
    });
  }

  /// Same floating-nav discipline as [AdoptHabitPage] — see the note there:
  /// route-name writes from dismissed overlays would otherwise un-hide the
  /// shell nav over this page's CTA.
  void _ensureNavHidden() {
    if (!mounted) return;
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.keypointComplete);
  }

  Future<void> _adopt(HabitEntity habit) async {
    if (_submittingHabitId != null) return;
    AppHaptic.select();
    setState(() => _submittingHabitId = habit.id);

    final result = await context.read<HabitCubit>().adopt(
      habitId: habit.id,
      reminderTime: (habit.defaultReminderTime?.isNotEmpty ?? false) ? habit.defaultReminderTime! : '08:00',
      packLength: _defaultPackLength,
      sourceKeypointId: widget.sourceKeypointId,
      sourceCourseId: widget.sourceCourseId,
    );

    if (!mounted) return;
    setState(() => _submittingHabitId = null);

    HabitTracking.startAdd(
      courseId: widget.sourceCourseId,
      habitId: habit.id,
      habitName: habit.title.text,
      isFullSlot: result == AdoptHabitResult.slotFull,
    );

    switch (result) {
      case AdoptHabitResult.success:
        AppHaptic.success();
      case AdoptHabitResult.slotFull:
        await SlotFullUpgradeSheet.show(context, pendingHabit: habit);
      case AdoptHabitResult.failure:
        context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
    }
  }

  /// A habit adopted on an earlier visit is not a dead row: while today's
  /// check-in is still open, the same tap files it right here — the reader
  /// just finished a lesson that reinforces this habit, which IS the practice.
  Future<void> _checkIn(UserHabitEntity userHabit) async {
    if (_submittingHabitId != null) return;
    AppHaptic.select();
    setState(() => _submittingHabitId = userHabit.habitId);

    final ok = await context.read<HabitCubit>().checkIn(userHabit.id, done: true);

    if (!mounted) return;
    setState(() => _submittingHabitId = null);
    if (!ok) {
      context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
    }
  }

  void _continue() {
    AppHaptic.select();
    final adoptedAny = widget.habits.any((habit) => _adoptedRowFor(habit) != null);
    if (!adoptedAny && widget.habits.isNotEmpty) {
      // Same telemetry meaning as the old prompt's skip: offered, left empty.
      HabitTracking.startSkip(
        courseId: widget.sourceCourseId,
        habitId: widget.habits.first.id,
        habitName: widget.habits.first.title.text,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
      bloc: AppDI.injector.get<PageCubit>(),
      listenWhen: (previous, current) => previous.currentRouteName != current.currentRouteName && current.isPrimaryRoute,
      listener: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
          _ensureNavHidden();
        });
      },
      // Rebuild rows when the adopted set changes (adopt writes userHabits).
      child: BlocBuilder<HabitCubit, HabitState>(
        buildWhen: (previous, current) => previous.userHabits != current.userHabits,
        builder: (context, _) => Scaffold(
          backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundBrandSoft),
          body: ThemedBackground(
            child: SafePage(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            28.verticalSpace,
                            SvgPicture.asset(AppAsset.svg.common.habitEmptyIllustration, width: 118.w),
                            18.verticalSpace,
                            AppText(
                              context.l10n.habit.habitSuggestTitle,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              style: AppStyle.text20.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                              ),
                            ),
                            8.verticalSpace,
                            AppText(
                              context.l10n.habit.habitSuggestSubtitle,
                              textAlign: TextAlign.center,
                              style: AppStyle.text12.copyWith(
                                fontWeight: FontWeight.w700,
                                color: studyThemeAccentOnBg(context, AppCustomColor.brandPrimary),
                              ),
                            ),
                            18.verticalSpace,
                            for (final habit in widget.habits) ...[
                              _habitRow(context, habit),
                              10.verticalSpace,
                            ],
                          ],
                        ),
                      ),
                    ),
                    12.verticalSpace,
                    Semantics(
                      button: true,
                      child: Material(
                        color: AppCustomColor.brandPrimary,
                        borderRadius: BorderRadius.circular(999.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999.r),
                          onTap: _continue,
                          child: Container(
                            height: 54.h,
                            alignment: Alignment.center,
                            child: AppText(
                              context.l10n.common.kContinue,
                              style: AppStyle.text16.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textWhite),
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
      ),
    );
  }

  /// One suggested habit (design row): white card, domain icon, title, and the
  /// state chip. The whole row is the tap target — the chip alone is too small
  /// a thumb target for the row's single action. The action ladders down:
  /// not adopted → adopt; adopted with today's check-in open → check in;
  /// adopted and checked in → nothing left to do here.
  Widget _habitRow(BuildContext context, HabitEntity habit) {
    final adopted = _adoptedRowFor(habit);
    final canCheckIn = adopted != null && adopted.isActive && !adopted.todayDone;
    final isDone = adopted != null && !canCheckIn;
    final isSubmitting = _submittingHabitId == habit.id;

    return Semantics(
      button: !isDone,
      label: habit.title.text,
      child: Material(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: isDone
              ? null
              : canCheckIn
              ? () => _checkIn(adopted)
              : () => _adopt(habit),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [BoxShadow(color: const Color(0x14141828), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                HabitDomainIcon(skillsetId: habit.skillsetId, size: 34),
                12.horizontalSpace,
                Expanded(
                  child: AppText(
                    habit.title.text,
                    maxLines: 2,
                    style: AppStyle.text13.copyWith(fontWeight: FontWeight.w600, height: 1.4, color: AppCustomColor.textPrimary),
                  ),
                ),
                10.horizontalSpace,
                _stateChip(context, canCheckIn: canCheckIn, isDone: isDone, isSubmitting: isSubmitting),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stateChip(BuildContext context, {required bool canCheckIn, required bool isDone, required bool isSubmitting}) {
    if (isSubmitting) {
      return SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2, color: AppCustomColor.brandPrimary));
    }
    final label = isDone
        ? context.l10n.habit.habitSuggestCheckedIn
        : canCheckIn
        ? context.l10n.habit.habitSuggestCheckIn
        : context.l10n.habit.habitSuggestAdd;
    return Container(
      height: 24.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDone ? AppCustomColor.kpResultCorrectSurface : AppCustomColor.brandPrimary50,
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: AppText(
        label,
        // Design 11.5/700 — the app scale has no 11.5.
        style: TextStyle(
          fontFamily: AppFont.mulish,
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
          color: isDone ? AppCustomColor.successGreen : AppCustomColor.brandPrimary,
        ),
      ),
    );
  }
}
