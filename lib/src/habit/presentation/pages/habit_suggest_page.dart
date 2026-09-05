part of '../../habit.dart';

/// The recap-flow habit step (design "3 · Learning" → Recap / "5 · Habit" →
/// Add a habit): the lesson's suggested habits as tappable rows, each flipping
/// to an "Added" chip when adopted, and one Continue that always moves the
/// flow on to the lesson-complete screen.
///
/// This SITS BETWEEN the recap flip card and lesson complete — it replaced the
/// old placement where [AdoptHabitPage] popped up after "Skip to next lesson",
/// i.e. after the reader had already said they were leaving. Unlike that page
/// (radio pick + one Add), this one adopts per row: several habits can be
/// added in one visit, and Continue is never blocked on choosing.
///
/// Add is the ONLY action here (per design — no check-in affordance on this
/// screen), and a first add files today's check-in in the same gesture: the
/// reader just finished the lesson that practises this habit, so the day is
/// already earned — showing a freshly added habit as "not done today" would
/// ask them to do again what they just did.
class HabitSuggestPage extends StatefulWidget {
  final List<HabitEntity> habits;
  final String? sourceKeypointId;
  final String? sourceCourseId;

  /// Luồng 7 — the lesson this page belongs to, carried so the Coach door
  /// opened from here is scoped to it. Without it the server's
  /// "already shown this lesson" guard degrades to once per DAY across every
  /// lesson, and the second lesson of a day that adds a habit gets a dead tap.
  final String? sourceLessonId;

  const HabitSuggestPage({
    super.key,
    required this.habits,
    this.sourceKeypointId,
    this.sourceCourseId,
    this.sourceLessonId,
  });

  /// Pushed on the ROOT navigator so it overlays the shell (and its floating
  /// nav) exactly like [AdoptHabitPage] did. Fades in/out — the whole
  /// completion flow (recap → habit → lesson complete) speaks in fades, and a
  /// MaterialPageRoute slide here read as being shoved sideways between them.
  /// Resolves when the reader continues; navigation onward is THIS page's job
  /// (see [_continue]) so the lesson-complete screen is already underneath
  /// when the fade-out reveals it.
  static Future<void> push(
    BuildContext context, {
    required List<HabitEntity> habits,
    String? sourceKeypointId,
    String? sourceCourseId,
    String? sourceLessonId,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => BlocProvider.value(
          value: AppDI.injector.get<HabitCubit>(),
          child: HabitSuggestPage(
            habits: habits,
            sourceKeypointId: sourceKeypointId,
            sourceCourseId: sourceCourseId,
            sourceLessonId: sourceLessonId,
          ),
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }

  @override
  State<HabitSuggestPage> createState() => _HabitSuggestPageState();
}

class _HabitSuggestPageState extends State<HabitSuggestPage> {
  static const int _defaultPackLength = 3;

  /// Habit id currently mid-adopt — its row shows a spinner chip and every
  /// other row ignores taps, so two quick taps can't fire two writes.
  String? _submittingHabitId;

  /// Luồng 7 — habit ids adopted during THIS visit, in the order they were
  /// added.
  ///
  /// Deliberately NOT `_adoptedRowFor(habit) != null`: that asks whether the
  /// habit is in the kho AT ALL, which is true for one adopted last week — and
  /// the Coach's invitation says "bạn vừa thêm", a claim about *now*. Reusing
  /// kho-membership there told readers they had just added three habits they
  /// had not touched today, and the server (which counts habits created since
  /// midnight) then found nothing to talk about and stayed silent, so the
  /// invitation's button did nothing.
  final List<String> _justAdded = <String>[];

  /// Design `shfToast`: "Habit added to your list" fades in under the list
  /// after a successful add, then fades back out on its own.
  bool _showAddedToast = false;
  Timer? _addedToastTimer;

  void _flashAddedToast() {
    _addedToastTimer?.cancel();
    setState(() => _showAddedToast = true);
    _addedToastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showAddedToast = false);
    });
  }

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

  @override
  void dispose() {
    _addedToastTimer?.cancel();
    super.dispose();
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

    final habitCubit = context.read<HabitCubit>();
    final result = await habitCubit.adopt(
      habitId: habit.id,
      reminderTime: (habit.defaultReminderTime?.isNotEmpty ?? false) ? habit.defaultReminderTime! : '08:00',
      packLength: _defaultPackLength,
      sourceKeypointId: widget.sourceKeypointId,
      sourceCourseId: widget.sourceCourseId,
    );

    // The lesson the reader just finished IS today's practice of this habit,
    // so a first add files the day's check-in in the same gesture. Best-effort:
    // a failed check-in must not undo or hide a successful add.
    if (result == AdoptHabitResult.success) {
      // Recorded before the mounted check: nothing renders from it, and the
      // check below returns on a page that is already gone.
      if (!_justAdded.contains(habit.id)) _justAdded.add(habit.id);

      final adopted = _adoptedRowFor(habit);
      if (adopted != null && !adopted.todayDone) {
        await habitCubit.checkIn(adopted.id, done: true);
      }
    }

    if (!mounted) return;
    setState(() => _submittingHabitId = null);
    if (result == AdoptHabitResult.success) {
      // Day zero of the gift schedule (see adopt_habit_page for the paired
      // hook). This page stays on screen, so post-frame is safe here.
      scheduleGiftPopupCheck(context, dayZeroEvent: true);
    }

    HabitTracking.startAdd(
      courseId: widget.sourceCourseId,
      habitId: habit.id,
      habitName: habit.title.text,
      isFullSlot: result == AdoptHabitResult.slotFull,
    );

    switch (result) {
      case AdoptHabitResult.success:
        AppHaptic.success();
        _flashAddedToast();
      case AdoptHabitResult.slotFull:
        await SlotFullUpgradeSheet.show(context, pendingHabit: habit);
      case AdoptHabitResult.failure:
        context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
    }
  }

  Future<void> _continue() async {
    AppHaptic.select();
    final adopted = widget.habits.where((habit) => _adoptedRowFor(habit) != null).toList();
    final adoptedAny = adopted.isNotEmpty;

    // Luồng 7 — a habit added here is at its most vivid right now: the reader
    // still knows why they added it. So the Coach offers ONE practice before
    // the lesson-complete screen, on this page rather than after it, and
    // ⟨Lúc khác⟩ simply goes on — the habit is in the kho and Home can practise
    // it any day.
    if (_justAdded.isNotEmpty) {
      // One invitation per trip out of the lesson: the keypoint talk stands
      // down because this one is about to run.
      CoachKeypointInvite.suppressNext();
      // Owner 2026-09-05: closing the sheet puts the reader back on THIS
      // invitation, not on the way to the next keypoint. Backing out of the
      // Coach is not a decision to move on.
      while (true) {
        if (!mounted) return;
        final accepted = await CoachInvitePopup.show(
          context,
          kind: CoachInviteKind.newHabit,
          newHabitCount: _justAdded.length,
        );
        if (!mounted) return;
        if (accepted != true) break;

        final courseId = await showCoachSheet(
          context,
          entry: CoachEntry.lesson,
          lessonId: widget.sourceLessonId,
          // One habit needs no question; the server asks which one when the
          // reader added several. The HABIT's id, not the user_habit row's —
          // the server resolves the row from it (`userHabitRowFor`), and a row
          // id handed over there matches nothing.
          habitId: _justAdded.length == 1 ? _justAdded.single : null,
        );
        if (!mounted) return;
        // The course the Coach offered. This return value used to be thrown
        // away, so "Học ngay" here closed the sheet and did nothing — and with
        // the loop below it would have closed and asked again for ever.
        if (courseId != null && courseId.isNotEmpty) {
          final navContext = AppConfig.instance.context ?? context;
          if (navContext.mounted &&
              AppDI.injector.get<DeeplinkCubit>().openCourseRoadmapFromCoach(navContext, courseId)) {
            return;
          }
        }
        // Simply closed — round the loop and offer it again.
      }
    }

    if (!adoptedAny && widget.habits.isNotEmpty) {
      // Same telemetry meaning as the old prompt's skip: offered, left empty.
      HabitTracking.startSkip(
        courseId: widget.sourceCourseId,
        habitId: widget.habits.first.id,
        habitName: widget.habits.first.title.text,
      );
    }
    // Swap the page UNDERNEATH this overlay to lesson-complete first, then
    // fade this page out one frame later — the fade reveals the destination
    // directly instead of flashing the deck it was pushed over. Same pattern
    // as the quiz's exit to the roadmap.
    AppDI.injector.get<LessonCubit>().openKeypointComplete();
    final navigator = Navigator.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.canPop()) navigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
      bloc: AppDI.injector.get<PageCubit>(),
      listenWhen: (previous, current) => previous.currentRouteName != current.currentRouteName && current.isPrimaryRoute,
      listener: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!canAssertOwnRouteName(context)) return;
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
                            // Design `illus-full-slots` at 196w — the slot-box
                            // art the slot-full sheet also uses, not the dashed
                            // "empty" variant this page first shipped with.
                            SvgPicture.asset(AppAsset.svg.common.habitSlotFullIllustration, width: 196.w),
                            20.verticalSpace,
                            AppText(
                              context.l10n.habit.habitSuggestTitle,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              // Design 24/700, lh 1.3.
                              style: TextStyle(
                                fontFamily: AppFont.mulish,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                              ),
                            ),
                            14.verticalSpace,
                            AppText(
                              context.l10n.habit.habitSuggestSubtitle,
                              textAlign: TextAlign.center,
                              // Design 13.5/600.
                              style: TextStyle(
                                fontFamily: AppFont.mulish,
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color: studyThemeAccentOnBg(context, AppCustomColor.brandPrimary),
                              ),
                            ),
                            18.verticalSpace,
                            for (final habit in widget.habits) ...[
                              _habitRow(context, habit),
                              10.verticalSpace,
                            ],
                            // Design `shfToast`: a dark confirmation pill fades
                            // in under the list after an add. The slot is
                            // always reserved so its appearance never shifts
                            // the rows above it.
                            SizedBox(
                              height: 44.h,
                              child: Center(
                                child: AnimatedOpacity(
                                  opacity: _showAddedToast ? 1 : 0,
                                  duration: const Duration(milliseconds: 250),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D121C),
                                      borderRadius: BorderRadius.circular(99.r),
                                      boxShadow: const [BoxShadow(color: Color(0x380D121C), blurRadius: 20, offset: Offset(0, 8))],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_rounded, size: 14.w, color: const Color(0xFF6FE0A5)),
                                        8.horizontalSpace,
                                        AppText(
                                          context.l10n.habit.habitSuggestAddedToast,
                                          // Design 12.5/700.
                                          style: TextStyle(
                                            fontFamily: AppFont.mulish,
                                            fontSize: 12.5.sp,
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

  /// One suggested habit (design "Start first habit" row): white card with a
  /// hairline border, the habit's picture, the title, and a round "+" add button
  /// ("Added" chip once adopted). The whole row stays the tap target — the 34px
  /// button alone is too small a thumb target for the row's single action.
  ///
  /// The tile shows the habit's OWN picture, like every other habit surface
  /// ([HabitDomainIcon]). It once forced one uniform sprout on every row, back
  /// when the only alternative was the SKILLSET logo and three domain logos in a
  /// column read as three different apps; 37db4917 overturned that once habits
  /// carried their own pictures, and the design rewrite here re-pinned the
  /// sprout by accident. A habit with no picture still lands on the design's
  /// sprout tile ([_sproutTile]), so a half-filled catalog looks unchanged.
  Widget _habitRow(BuildContext context, HabitEntity habit) {
    final isAdded = _adoptedRowFor(habit) != null;
    final isSubmitting = _submittingHabitId == habit.id;

    return Semantics(
      button: !isAdded,
      label: habit.title.text,
      child: Material(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: isAdded ? null : () => _adopt(habit),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              // Design: 1px hairline, green-tinted once adopted.
              border: Border.all(color: isAdded ? const Color(0xFFCBEBD6) : const Color(0xFFE3E8EF)),
            ),
            child: Row(
              children: [
                HabitDomainIcon(
                  skillsetId: habit.skillsetId,
                  imageUrl: habit.image,
                  size: 44,
                  radius: 12,
                  fallback: _sproutTile(),
                ),
                14.horizontalSpace,
                Expanded(
                  child: AppText(
                    habit.title.text,
                    maxLines: 2,
                    // Design 15/600, lh 1.4.
                    style: TextStyle(
                      fontFamily: AppFont.mulish,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: AppCustomColor.textPrimary,
                    ),
                  ),
                ),
                10.horizontalSpace,
                _addButton(context, isAdded: isAdded, isSubmitting: isSubmitting),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The design's placeholder tile (`habit-plant.svg` on `#E9F6EC`), shown for a
  /// habit that has no picture of its own and inherits none from its skillset.
  Widget _sproutTile() {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6EC),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(AppAsset.svg.common.habitAddedPlant, width: 30.w, height: 30.w),
    );
  }

  /// Design's add affordance: a solid round "+" (34px, brand blue) that turns
  /// into the light-green "Added" chip once adopted; a spinner in the same
  /// footprint while the write is in flight.
  Widget _addButton(BuildContext context, {required bool isAdded, required bool isSubmitting}) {
    if (isSubmitting) {
      return SizedBox(
        width: 34.w,
        height: 34.w,
        child: Center(
          child: SizedBox(
            width: 16.w,
            height: 16.w,
            child: const CircularProgressIndicator(strokeWidth: 2, color: AppCustomColor.brandPrimary),
          ),
        ),
      );
    }
    if (isAdded) {
      return Container(
        height: 26.h,
        padding: EdgeInsets.symmetric(horizontal: 11.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE9F6EC),
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: AppText(
          context.l10n.habit.habitSuggestAdded,
          // Design 11.5/700 on #2E9E77.
          style: TextStyle(
            fontFamily: AppFont.mulish,
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: const Color(0xFF2E9E77),
          ),
        ),
      );
    }
    return Container(
      width: 34.w,
      height: 34.w,
      decoration: const BoxDecoration(color: AppCustomColor.brandPrimary, shape: BoxShape.circle),
      child: Icon(Icons.add_rounded, size: 20.w, color: AppCustomColor.textWhite),
    );
  }
}
