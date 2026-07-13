part of '../../habit.dart';

/// Post-lesson "Upgrade habit" prompt (flowchart: Lesson complete → Upgrade
/// habit): shows the CURRENT habit against a suggested NEW habit. "Upgrade my
/// habit" adopts the new one — routing through the slot gate (success popup,
/// or the slot-full sheet → paywall / manage slots). "Keep current" dismisses.
class UpgradeHabitPage extends StatefulWidget {
  final UserHabitEntity currentHabit;
  final HabitEntity newHabit;

  const UpgradeHabitPage({super.key, required this.currentHabit, required this.newHabit});

  /// Pushed on the root navigator (from the lesson-complete flow), so the
  /// HabitCubit provider isn't in scope — re-provide the singleton.
  static Future<void> push(BuildContext context, {required UserHabitEntity currentHabit, required HabitEntity newHabit}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: AppDI.injector.get<HabitCubit>(),
          child: UpgradeHabitPage(currentHabit: currentHabit, newHabit: newHabit),
        ),
      ),
    );
  }

  @override
  State<UpgradeHabitPage> createState() => _UpgradeHabitPageState();
}

class _UpgradeHabitPageState extends State<UpgradeHabitPage> {
  bool _isSubmitting = false;

  Future<void> _upgrade() async {
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
        await SlotFullUpgradeSheet.show(context, pendingHabit: widget.newHabit);
      case AdoptHabitResult.failure:
        context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundBrandSoft,
      body: SafePage(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              40.verticalSpace,
              // CURRENT HABIT — soft lavender card
              _UpgradeCard(
                label: context.l10n.habit.upgradeCurrentLabel,
                title: widget.currentHabit.displayTitle,
                skillsetId: widget.currentHabit.habit?.skillsetId ?? '',
                highlighted: false,
              ),
              16.verticalSpace,
              // NEW HABIT — white elevated card
              _UpgradeCard(
                label: context.l10n.habit.upgradeNewLabel,
                title: widget.newHabit.title.text,
                skillsetId: widget.newHabit.skillsetId,
                highlighted: true,
              ),
              const Spacer(),
              DButton(
                text: context.l10n.habit.upgradeButton,
                backgroundColor: AppCustomColor.brandPrimary,
                size: Size(double.infinity, 54.h),
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
                onPressed: _isSubmitting ? null : _upgrade,
              ),
              4.verticalSpace,
              DButton(
                text: context.l10n.habit.upgradeKeepCurrentButton,
                buttonType: DButtonType.text,
                onPressed: () => Navigator.of(context).pop(),
              ),
              20.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final String label;
  final String title;
  final String skillsetId;
  final bool highlighted;

  const _UpgradeCard({
    required this.label,
    required this.title,
    required this.skillsetId,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: highlighted ? 28.h : 20.h),
      decoration: BoxDecoration(
        color: highlighted ? AppCustomColor.backgroundWhite : AppCustomColor.brandPrimary50,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: highlighted ? [BoxShadow(color: AppCustomColor.brandPrimary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            label,
            style: AppStyle.text12.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.1),
          ),
          if (highlighted) ...[
            16.verticalSpace,
            HabitDomainIcon(skillsetId: skillsetId, size: 48),
          ],
          highlighted ? 16.verticalSpace : 8.verticalSpace,
          AppText(
            title,
            textAlign: TextAlign.center,
            style: highlighted ? AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary) : AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
          ),
        ],
      ),
    );
  }
}
