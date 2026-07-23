part of '../../habit.dart';

/// "Ready to set" / swap-for-the-new-habit sheet (Figma 11337:22757 — a modal
/// bottom sheet with a rounded top over the dimmed upgrade screen). Lists the
/// user's habits with per-row toggles so they can pause an active one to free a
/// slot, then "Confirm changes" adopts the pending NEW habit. Reached only when
/// a slot-full block is in play, so it always carries the pending [newHabit].
class ManageSlotsPage extends StatefulWidget {
  final HabitEntity newHabit;

  const ManageSlotsPage({super.key, required this.newHabit});

  static Future<void> show(BuildContext context, {required HabitEntity newHabit}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Sheet lives under the root navigator, outside the page's provider scope
      // — resolve the singleton cubit from DI (mirrors EditHabitSheet).
      builder: (_) => BlocProvider.value(
        value: AppDI.injector.get<HabitCubit>(),
        child: ManageSlotsPage(newHabit: newHabit),
      ),
    );
  }

  @override
  State<ManageSlotsPage> createState() => _ManageSlotsPageState();
}

class _ManageSlotsPageState extends State<ManageSlotsPage> {
  bool _isSubmitting = false;
  // Per-row busy tracking (a single bool would disable every row while only
  // one is in flight) — blocks re-tap on that row and shows its spinner.
  final Set<String> _togglingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) HabitTracking.manageScrView();
    });
  }

  Future<void> _togglePause(UserHabitEntity userHabit, bool active) async {
    // Pausing frees a slot; resuming can re-hit the cap — handled below,
    // mirroring _confirm()'s slotFull/failure snackbar handling.
    HabitTracking.manageToggle(userHabit, active: active);
    setState(() => _togglingIds.add(userHabit.id));
    final cubit = context.read<HabitCubit>();
    try {
      final result = await cubit.setActive(userHabit.id, active);
      if (!mounted) return;
      switch (result) {
        case AdoptHabitResult.slotFull:
          context.showDSnackBar(
            message: context.l10n.habit.slotFullTitle(limit: cubit.state.freeActiveSlots),
            type: MessageType.info,
          );
        case AdoptHabitResult.failure:
          context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
        case AdoptHabitResult.success:
          break;
      }
    } finally {
      if (mounted) setState(() => _togglingIds.remove(userHabit.id));
    }
  }

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    HabitTracking.manageConfirm();
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
        final goToHabit = await HabitAddedPopup.showUpgraded(context);
        if (!mounted) return;
        // SlotFullUpgradeSheet already pops itself before opening this sheet
        // (see slot_full_upgrade_sheet.dart), so the page that hit the slot
        // cap (AdoptHabitPage/UpgradeHabitPage) sits directly beneath this
        // one — pop both, or the user lands back on that "pick a habit"
        // screen and can keep adopting duplicates. Pass `false` so, if the
        // page below is AdoptHabitPage, its caller doesn't show its own
        // "added" popup on top of the "upgraded" one we already showed.
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.pop(false);
        if (goToHabit == true) {
          final roadmapCtx = AppConfig.instance.context;
          if (roadmapCtx != null && roadmapCtx.mounted) CourseRoadmapRoute().go(roadmapCtx);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final habitCtx = AppConfig.instance.context;
            if (habitCtx != null && habitCtx.mounted) HabitRoute().go(habitCtx);
          });
        }
      case AdoptHabitResult.slotFull:
        // Still over the cap — the user needs to pause one more first.
        context.showDSnackBar(
          message: context.l10n.habit.slotFullTitle(limit: cubit.state.freeActiveSlots),
          type: MessageType.info,
        );
      case AdoptHabitResult.failure:
        context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
    }
  }

  /// One habit row (Figma 11337:22773 / 11337:22797): existing habits sit on a
  /// gray card, the pending NEW habit on a brand-tinted one; both 20-radius
  /// with a hairline border, 48px domain icon and the pill switch.
  Widget _habitRow({
    required String title,
    required String skillsetId,
    required bool active,
    ValueChanged<bool>? onChanged,
    bool isNew = false,
    bool isLoading = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      // Uniform 74-high cards (Figma 11337:22773) so the rows read as an even
      // stack regardless of how the title wraps.
      constraints: BoxConstraints(minHeight: 74.h),
      decoration: BoxDecoration(
        color: isNew ? AppCustomColor.backgroundBrandSoft : AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isNew ? _kEditActiveRowBorder : AppCustomColor.borderDefault),
      ),
      child: Row(
        children: [
          HabitDomainIcon(skillsetId: skillsetId, size: 48),
          12.horizontalSpace,
          Expanded(
            child: AppText(
              title,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w600, height: 1.75),
            ),
          ),
          8.horizontalSpace,
          HabitSwitch(value: active, onChanged: onChanged, isLoading: isLoading),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Baked into the BottomCTA's own padding below instead of an outer
    // SafeArea — that keeps the white sheet flush to the bottom edge (no
    // transparent gap showing under it) while the button still clears the
    // home indicator / Android nav bar.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      // Rounded-top sheet over the dimmed upgrade screen (Figma 11337:22760).
      // Sizes to content up to most of the screen, leaving the backdrop peek.
      constraints: BoxConstraints(maxHeight: 0.92.sh),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: BlocBuilder<HabitCubit, HabitState>(
        builder: (context, state) {
          final habits = state.userHabits;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              12.verticalSpace,
              // Figma 11337:22762 — quiet tertiary back affordance, pinned at
              // the sheet's top so it stays reachable as the list scrolls.
              Semantics(
                button: true,
                label: context.l10n.common.back,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: () {
                    AppHaptic.select();
                    HabitTracking.manageBack();
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_left_rounded, size: 24.w, color: AppCustomColor.streakTextMuted),
                        4.horizontalSpace,
                        AppText(
                          context.l10n.common.back,
                          style: AppStyle.text14.copyWith(color: AppCustomColor.streakTextMuted, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: AppText(
                          context.l10n.habit.manageSlotsTitle,
                          textAlign: TextAlign.center,
                          style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
                        ),
                      ),
                      8.verticalSpace,
                      // Figma 11337:22768 — the waiting habit's NAME is bold
                      // inside the regular sentence. The l10n template embeds
                      // the name, so bold the last occurrence of it.
                      Builder(
                        builder: (context) {
                          final habitTitle = widget.newHabit.title.text;
                          final fullText = context.l10n.habit.manageSlotsNewHabitWaiting(habitTitle: habitTitle);
                          final markerIdx = habitTitle.isEmpty ? -1 : fullText.lastIndexOf(habitTitle);
                          final baseStyle = AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.75);
                          if (markerIdx < 0) {
                            return SizedBox(
                              width: double.infinity,
                              child: AppText(fullText, textAlign: TextAlign.center, style: baseStyle),
                            );
                          }
                          return SizedBox(
                            width: double.infinity,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: baseStyle,
                                children: [
                                  TextSpan(text: fullText.substring(0, markerIdx)),
                                  TextSpan(
                                    text: fullText.substring(markerIdx, markerIdx + habitTitle.length),
                                    style: baseStyle.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: fullText.substring(markerIdx + habitTitle.length)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      24.verticalSpace,
                      Row(
                        children: [
                          AppText(
                            context.l10n.habit.manageSlotsHabitSection.toUpperCase(),
                            style: AppStyle.text14.copyWith(color: AppCustomColor.streakTextMuted, fontWeight: FontWeight.w700),
                          ),
                          6.horizontalSpace,
                          AppText(
                            '${state.activeCount}/${state.freeActiveSlots}',
                            style: AppStyle.text14.copyWith(color: AppCustomColor.textQuaternary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      12.verticalSpace,
                      ...habits.map(
                        (h) => _habitRow(
                          title: h.displayTitle,
                          skillsetId: h.habit?.skillsetId ?? '',
                          active: h.isActive,
                          onChanged: (v) => _togglePause(h, v),
                          isLoading: _togglingIds.contains(h.id),
                        ),
                      ),
                      24.verticalSpace,
                      AppText(
                        context.l10n.habit.manageSlotsNewSection,
                        // Figma 11337:22796 — brand/primary (#4B44CA), not the
                        // #554FF0 button brand. Body/Default/Bold, no tracking.
                        style: AppStyle.text14.copyWith(color: AppCustomColor.streakActive, fontWeight: FontWeight.w700),
                      ),
                      12.verticalSpace,
                      _habitRow(
                        title: widget.newHabit.title.text,
                        skillsetId: widget.newHabit.skillsetId,
                        active: true,
                        onChanged: null,
                        isNew: true,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                // Figma 11337:22807 BottomCTA — 20 padding around the button.
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h + bottomInset),
                child: DButton(
                  text: context.l10n.habit.manageSlotsConfirmButton,
                  backgroundColor: AppCustomColor.brandPrimary,
                  size: Size(double.infinity, 54.h),
                  style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
                  onPressed: _isSubmitting ? null : _confirm,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
