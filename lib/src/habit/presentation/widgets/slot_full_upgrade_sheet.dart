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
      ManageSlotsPage.show(context, newHabit: habit);
    }
    // else: dismiss only — the user frees a slot from a habit's own edit sheet.
  }

  /// Title (Figma 11327:22669) is two-tone: the lead-in in text/primary, then
  /// the "N habit slots" count phrase in brand. Split on the number so it works
  /// for every locale (the count + everything after it is the brand phrase)
  /// without extra l10n keys.
  Widget _buildTitle(BuildContext context) {
    final limit = AppDI.injector.get<HabitCubit>().state.freeActiveSlots;
    final full = context.l10n.habit.slotFullTitle(limit: limit);
    final markerIndex = full.indexOf('$limit');
    final base = AppStyle.textBold24;
    final prefix = markerIndex > 0 ? full.substring(0, markerIndex) : '';
    final highlight = markerIndex >= 0 ? full.substring(markerIndex) : full;
    return Text.rich(
      TextSpan(
        children: [
          if (prefix.isNotEmpty)
            TextSpan(
              text: prefix,
              style: base.copyWith(color: AppCustomColor.textPrimary),
            ),
          TextSpan(
            text: highlight,
            style: base.copyWith(color: AppCustomColor.streakActive),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Subtitle (Figma 11327:22670): "New habit waiting — `name`" with the habit
  /// name bold. Split on the interpolated title so only the name is bold.
  Widget _buildSubtitle(BuildContext context) {
    final full = context.l10n.habit.slotFullSubtitle(habitTitle: pendingHabitTitle);
    final base = AppStyle.text14.copyWith(color: AppCustomColor.textSecondary);
    final nameIndex = pendingHabitTitle.isNotEmpty ? full.indexOf(pendingHabitTitle) : -1;
    if (nameIndex < 0) {
      return AppText(full, textAlign: TextAlign.center, style: base);
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: full.substring(0, nameIndex), style: base),
          TextSpan(
            text: full.substring(nameIndex),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bake the bottom safe-area inset into the card's padding instead of
    // wrapping in SafeArea — that keeps the white sheet flush to the bottom
    // edge (no transparent scrim strip showing under it) while the buttons
    // still clear the home indicator / Android nav bar.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // The plant-in-folder illustration (Figma 11327:22676) straddles the top
    // edge of the sheet: reserve 60.h of transparent scrim above the white
    // card and float the image over it, overlapping into the card's 52.h top
    // padding.
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 60.h),
          padding: EdgeInsets.fromLTRB(20.w, 52.h, 20.w, 20.h + bottomInset),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitle(context),
              8.verticalSpace,
              _buildSubtitle(context),
              24.verticalSpace,
              DButton(
                text: context.l10n.habit.slotFullUpgradeButton,
                backgroundColor: AppCustomColor.brandPrimary,
                size: Size(double.infinity, 54.h),
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
                onPressed: () => _upgrade(context),
              ),
              16.verticalSpace,
              DButton(
                text: context.l10n.habit.slotFullManageButton,
                backgroundColor: AppCustomColor.backgroundBrand,
                size: Size(double.infinity, 54.h),
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.streakActive),
                onPressed: () => _manage(context),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: SvgPicture.asset('assets/svg/common/habit_slot_full_illustration.svg', width: 176.w, height: 100.h),
        ),
      ],
    );
  }
}
