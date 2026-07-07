part of '../../habit.dart';

/// "Ready to set" / swap-for-the-new-habit screen (flowchart: slot-full notice
/// → Manage slots). Lists the user's habits with per-row toggles so they can
/// pause an active one to free a slot, then "Confirm changes" adopts the
/// pending NEW habit. Reached only when a slot-full block is in play, so it
/// always carries the pending [newHabit].
class ManageSlotsPage extends StatefulWidget {
  final HabitEntity newHabit;

  const ManageSlotsPage({super.key, required this.newHabit});

  static Future<void> push(BuildContext context, {required HabitEntity newHabit}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: AppDI.injector.get<HabitCubit>(),
          child: ManageSlotsPage(newHabit: newHabit),
        ),
      ),
    );
  }

  @override
  State<ManageSlotsPage> createState() => _ManageSlotsPageState();
}

class _ManageSlotsPageState extends State<ManageSlotsPage> {
  bool _isSubmitting = false;

  Future<void> _togglePause(UserHabitEntity userHabit, bool active) async {
    // Pausing frees a slot; resuming can re-hit the cap (handled by setActive).
    await context.read<HabitCubit>().setActive(userHabit.id, active);
  }

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final cubit = context.read<HabitCubit>();
    final result = await cubit.adopt(
      habitId: widget.newHabit.id,
      reminderTime: widget.newHabit.defaultReminderTime,
      packLength: 3,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case AdoptHabitResult.success:
        await HabitAddedPopup.showUpgraded(context);
        if (!mounted) return;
        Navigator.of(context).pop();
      case AdoptHabitResult.slotFull:
        // Still over the cap — the user needs to pause one more first.
        context.showDSnackBar(
          message: context.l10n.habit.slotFullTitle(limit: kFreeActiveHabitSlots),
          type: MessageType.info,
        );
      case AdoptHabitResult.failure:
        context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
    }
  }

  Widget _habitRow({required String title, required String icon, required bool active, ValueChanged<bool>? onChanged}) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundBrandSoft,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          AppText(icon, style: AppStyle.text24),
          12.horizontalSpace,
          Expanded(
            child: AppText(title, style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary)),
          ),
          8.horizontalSpace,
          Switch(
            value: active,
            activeTrackColor: AppCustomColor.brandPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeBody(
        child: BlocBuilder<HabitCubit, HabitState>(
          builder: (context, state) {
            final habits = state.userHabits;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                8.verticalSpace,
                Semantics(
                  button: true,
                  label: context.l10n.common.back,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 18.w, color: AppCustomColor.brandPrimary),
                          6.horizontalSpace,
                          AppText(context.l10n.common.back, style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        8.verticalSpace,
                        AppText(
                          context.l10n.habit.manageSlotsTitle,
                          style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
                        ),
                        8.verticalSpace,
                        AppText(
                          context.l10n.habit.manageSlotsNewHabitWaiting(habitTitle: widget.newHabit.title.text),
                          style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
                        ),
                        24.verticalSpace,
                        Row(
                          children: [
                            AppText(
                              context.l10n.habit.manageSlotsHabitSection,
                              style: AppStyle.text14.copyWith(color: AppCustomColor.streakTextMuted, fontWeight: FontWeight.w600),
                            ),
                            6.horizontalSpace,
                            AppText(
                              '${state.activeCount}/$kFreeActiveHabitSlots',
                              style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
                            ),
                          ],
                        ),
                        12.verticalSpace,
                        ...habits.map(
                          (h) => _habitRow(
                            title: h.displayTitle,
                            icon: h.displayIcon,
                            active: h.isActive,
                            onChanged: (v) => _togglePause(h, v),
                          ),
                        ),
                        24.verticalSpace,
                        AppText(
                          context.l10n.habit.manageSlotsNewSection,
                          style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.1),
                        ),
                        12.verticalSpace,
                        _habitRow(
                          title: widget.newHabit.title.text,
                          icon: widget.newHabit.icon,
                          active: true,
                          onChanged: null,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                  child: DButton(
                    text: context.l10n.habit.manageSlotsConfirmButton,
                    onPressed: _isSubmitting ? null : _confirm,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
