part of '../../habit.dart';

/// "Start first habit" / adopt flow (Figma 10788:53255): pick a habit from
/// the suggested list, then adopt (reminder time defaults silently — this
/// screen has no time picker). Pops `true` when adopted so the caller can
/// show [HabitAddedPopup]; pops `false`/null on "Skip" or back.
class AdoptHabitPage extends StatefulWidget {
  final List<HabitEntity> habits;
  final String? sourceKeypointId;
  final String? sourceCourseId;

  const AdoptHabitPage({
    super.key,
    required this.habits,
    this.sourceKeypointId,
    this.sourceCourseId,
  });

  @override
  State<AdoptHabitPage> createState() => _AdoptHabitPageState();
}

class _AdoptHabitPageState extends State<AdoptHabitPage> {
  static const int _defaultPackLength = 3;
  late HabitEntity _selectedHabit = widget.habits.first;
  // Figma 10788:53255 has no reminder-time picker on this screen — silently
  // default to the habit's suggested time (or 08:00) instead of asking.
  String _selectedReminderTime = '08:00';
  bool _isSubmitting = false;

  /// The "PROBLEM" headline (Figma 10788:53255) = the re-anchor reason the user
  /// picked for this course ("their why", §9.5) — the same "vấn đề" shown on the
  /// tracker cluster. Falls back to the course title, then the first suggested
  /// habit's own title, only when no reason was picked.
  String get _headline {
    final courseId = widget.sourceCourseId;
    if (courseId != null && courseId.isNotEmpty) {
      final reason = AppDI.injector.get<HabitCubit>().state.reanchorReasonByCourse[courseId]?.reason.text ?? '';
      if (reason.isNotEmpty) return reason;
      // FULL catalog (HomeCubit.skillsets), not ProgressCubit.myCourses — this
      // page is reached right after finishing a keypoint, so myCourses (only
      // courses with SAVED progress) can still be stale for this exact course.
      // Mirrors the same fix in habit_page.dart's _habitGroupTitle.
      final title = AppDI.injector.get<HomeCubit>().state.skillsets.resolveCourseByCourseId(courseId).title.text;
      if (title.isNotEmpty) return title;
    }
    return widget.habits.first.title.text;
  }

  @override
  void initState() {
    super.initState();
    _applyHabitDefaults(_selectedHabit);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureNavHidden());
  }

  /// This full-screen adopt page pushes the paywall (via SlotFullUpgradeSheet);
  /// when the paywall pops, the route observer resets currentRouteName to a
  /// PRIMARY name, which un-hides the shell's floating nav over this page (and
  /// clips its "Add habit" CTA). Keep the nav hidden by asserting this flow's
  /// non-primary route name on mount and reclaiming it whenever a primary name
  /// lands while this page is the current route. Mirrors keypoint_complete_page.
  void _ensureNavHidden() {
    if (!mounted) return;
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.keypointComplete);
  }

  void _applyHabitDefaults(HabitEntity habit) {
    final defaultTime = habit.defaultReminderTime;
    if (defaultTime != null && defaultTime.isNotEmpty) {
      _selectedReminderTime = defaultTime;
    }
  }

  Future<void> _start() async {
    AppHaptic.success();
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final result = await context.read<HabitCubit>().adopt(
      habitId: _selectedHabit.id,
      reminderTime: _selectedReminderTime,
      packLength: _defaultPackLength,
      sourceKeypointId: widget.sourceKeypointId,
      sourceCourseId: widget.sourceCourseId,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case AdoptHabitResult.success:
        Navigator.of(context).pop(true);
      case AdoptHabitResult.slotFull:
        await SlotFullUpgradeSheet.show(context, pendingHabit: _selectedHabit);
      case AdoptHabitResult.failure:
        context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
    }
  }

  Widget _buildHabitOption(HabitEntity habit) {
    final selected = habit.id == _selectedHabit.id;
    return Semantics(
      button: true,
      selected: selected,
      label: habit.title.text,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => setState(() {
          _selectedHabit = habit;
          _applyHabitDefaults(habit);
        }),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: selected ? AppCustomColor.backgroundBrandSoft : AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected ? AppCustomColor.streakActive : AppCustomColor.borderSecondary,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              HabitDomainIcon(skillsetId: habit.skillsetId, size: 32),
              12.horizontalSpace,
              Expanded(
                child: AppText(
                  habit.title.text,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700),
                ),
              ),
              8.horizontalSpace,
              if (selected)
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppCustomColor.streakActive,
                  ),
                  child: Icon(Icons.check, size: 13.w, color: AppCustomColor.textWhite),
                ),
            ],
          ),
        ),
      ),
    );
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
      child: Scaffold(
        // Transparent only when a custom study background is active.
        backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.brandPrimary50),
        body: ThemedBackground(
          child: SafePage(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  24.verticalSpace,
                  Center(
                    child: AppText(
                      context.l10n.habit.adoptProblemLabel,
                      style: AppStyle.text12.copyWith(
                        color: studyThemeAccentOnBg(context, AppCustomColor.streakActive),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  4.verticalSpace,
                  AppText(
                    _headline,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold24.copyWith(color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
                  ),
                  16.verticalSpace,
                  Expanded(
                    child: ThemedGlassCard(
                      padding: EdgeInsets.all(16.w),
                      radius: 20,
                      shadow: [BoxShadow(color: AppCustomColor.borderDefault, blurRadius: 4)],
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              context.l10n.habit.adoptChooseHabitLabel,
                              style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
                            ),
                            12.verticalSpace,
                            ...widget.habits.map(_buildHabitOption),
                          ],
                        ),
                      ),
                    ),
                  ),
                  16.verticalSpace,
                  DButton(
                    text: context.l10n.habit.adoptAddButton,
                    backgroundColor: AppCustomColor.brandPrimary,
                    size: Size(double.infinity, 54.h),
                    style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
                    onPressed: _isSubmitting ? null : _start,
                  ),
                  4.verticalSpace,
                  DButton(
                    text: context.l10n.habit.adoptRemindLaterButton,
                    buttonType: DButtonType.text,
                    style: AppStyle.textBold14.copyWith(color: studyThemeAccentOnBg(context, AppCustomColor.streakActive)),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  12.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
