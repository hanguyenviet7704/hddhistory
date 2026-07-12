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

  /// The course/lesson this adopt flow was suggested from, shown as the
  /// "PROBLEM" headline (Figma 10788:53255). Falls back to the first
  /// suggested habit's own title when no course can be resolved.
  String get _headline {
    final courseId = widget.sourceCourseId;
    if (courseId != null && courseId.isNotEmpty) {
      final course = AppDI.injector.get<ProgressCubit>().state.myCourses.where((c) => c.id == courseId).firstOrNull;
      final title = course?.title.text ?? '';
      if (title.isNotEmpty) return title;
    }
    return widget.habits.first.title.text;
  }

  @override
  void initState() {
    super.initState();
    _applyHabitDefaults(_selectedHabit);
  }

  void _applyHabitDefaults(HabitEntity habit) {
    final defaultTime = habit.defaultReminderTime;
    if (defaultTime != null && defaultTime.isNotEmpty) {
      _selectedReminderTime = defaultTime;
    }
  }

  Future<void> _start() async {
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
              AppText(habit.icon, style: AppStyle.text24),
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
    return Scaffold(
      backgroundColor: AppCustomColor.brandPrimary50,
      body: SafeBody(
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
                    color: AppCustomColor.streakActive,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              4.verticalSpace,
              AppText(
                _headline,
                textAlign: TextAlign.center,
                style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
              ),
              16.verticalSpace,
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppCustomColor.backgroundWhite,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [BoxShadow(color: AppCustomColor.borderDefault, blurRadius: 4)],
                  ),
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
                style: AppStyle.textBold14.copyWith(color: AppCustomColor.streakActive),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              12.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
