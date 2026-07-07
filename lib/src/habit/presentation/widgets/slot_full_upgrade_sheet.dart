part of '../../habit.dart';

/// Shown when the server rejects an adopt/activate with 409 SLOT_FULL
/// (design.md 5.6, flowchart "Filled habit slots"). "Go unlimited slots"
/// routes to the paywall. "Manage slots" opens the [ManageSlotsPage] swap
/// screen when there's a pending new habit to adopt; otherwise (e.g. resuming
/// a paused habit) it just dismisses back so the user can pause one from the
/// edit sheet.
class SlotFullUpgradeSheet extends StatelessWidget {
  final String pendingHabitTitle;
  final HabitEntity? pendingHabit;

  const SlotFullUpgradeSheet({super.key, required this.pendingHabitTitle, this.pendingHabit});

  static Future<void> show(BuildContext context, {String? pendingHabitTitle, HabitEntity? pendingHabit}) {
    final title = pendingHabit?.title.text ?? pendingHabitTitle ?? '';
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SlotFullUpgradeSheet(pendingHabitTitle: title, pendingHabit: pendingHabit),
    );
  }

  void _upgrade(BuildContext context) {
    Navigator.of(context).pop();
    AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.habit);
    PaywallRoute().push(context);
  }

  void _manage(BuildContext context) {
    Navigator.of(context).pop();
    final habit = pendingHabit;
    if (habit != null) {
      ManageSlotsPage.push(context, newHabit: habit);
    }
    // else: dismiss only — the user frees a slot from a habit's own edit sheet.
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              context.l10n.habit.slotFullTitle(limit: kFreeActiveHabitSlots),
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
            ),
            8.verticalSpace,
            AppText(
              context.l10n.habit.slotFullSubtitle(habitTitle: pendingHabitTitle),
              style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
            ),
            24.verticalSpace,
            DButton(
              text: context.l10n.habit.slotFullUpgradeButton,
              onPressed: () => _upgrade(context),
            ),
            12.verticalSpace,
            DButton(
              text: context.l10n.habit.slotFullManageButton,
              buttonType: DButtonType.outline,
              textColor: AppCustomColor.brandPrimary,
              onPressed: () => _manage(context),
            ),
          ],
        ),
      ),
    );
  }
}
