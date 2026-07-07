part of '../../habit.dart';

/// "Start first habit" / adopt flow (Figma 10788:53255, design.md 5.2): pick
/// a habit from the library list, choose a daily reminder time, then adopt.
/// Pops `true` when the habit was adopted so the caller can show
/// [HabitAddedPopup]; pops `false`/null on "Remind me later" or back.
class AdoptHabitPage extends StatefulWidget {
  final List<HabitEntity> habits;

  const AdoptHabitPage({super.key, required this.habits});

  @override
  State<AdoptHabitPage> createState() => _AdoptHabitPageState();
}

class _AdoptHabitPageState extends State<AdoptHabitPage> {
  static const int _defaultPackLength = 3;
  late HabitEntity _selectedHabit = widget.habits.first;
  String _selectedReminderTime = '08:00';
  bool _isSubmitting = false;

  static const _reminderOptions = [
    ('08:00', 'adoptReminderMorning'),
    ('13:00', 'adoptReminderAfternoon'),
    ('20:00', 'adoptReminderEvening'),
  ];

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
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AppText(habit.icon, style: AppStyle.text24),
              12.horizontalSpace,
              Expanded(
                child: AppText(
                  habit.title.text,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary),
                ),
              ),
              8.horizontalSpace,
              if (selected)
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppCustomColor.brandPrimary,
                  ),
                  child: Icon(Icons.check, size: 14.w, color: AppCustomColor.textWhite),
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
      backgroundColor: AppCustomColor.backgroundBrandSoft,
      body: SafeBody(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              24.verticalSpace,
              Center(
                child: AppText(
                  context.l10n.habit.adoptHeaderLabel,
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.brandPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              20.verticalSpace,
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppCustomColor.backgroundWhite.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          context.l10n.habit.adoptChooseHabitLabel,
                          style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
                        ),
                        12.verticalSpace,
                        ...widget.habits.map(_buildHabitOption),
                        16.verticalSpace,
                        AppText(
                          context.l10n.habit.adoptReminderLabel,
                          style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
                        ),
                        12.verticalSpace,
                        Wrap(
                          spacing: 8.w,
                          children: _reminderOptions.map((option) {
                            final (time, labelKey) = option;
                            final selected = _selectedReminderTime == time;
                            final label = switch (labelKey) {
                              'adoptReminderMorning' => context.l10n.habit.adoptReminderMorning,
                              'adoptReminderAfternoon' => context.l10n.habit.adoptReminderAfternoon,
                              _ => context.l10n.habit.adoptReminderEvening,
                            };
                            return Semantics(
                              button: true,
                              selected: selected,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(1000.r),
                                onTap: () => setState(() => _selectedReminderTime = time),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: selected ? AppCustomColor.brandPrimary : AppCustomColor.backgroundWhite,
                                    borderRadius: BorderRadius.circular(1000.r),
                                    border: Border.all(
                                      color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
                                    ),
                                  ),
                                  child: AppText(
                                    label,
                                    style: AppStyle.text14.copyWith(
                                      color: selected ? AppCustomColor.textWhite : AppCustomColor.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              16.verticalSpace,
              DButton(
                text: context.l10n.habit.adoptAddButton,
                onPressed: _isSubmitting ? null : _start,
              ),
              4.verticalSpace,
              DButton(
                text: context.l10n.habit.adoptRemindLaterButton,
                buttonType: DButtonType.text,
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
