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
      // Transparent only when a custom study background is active.
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundBrandSoft),
      body: ThemedBackground(
        child: SafePage(
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
                  imageUrl: widget.currentHabit.habit?.image ?? '',
                  highlighted: false,
                ),
                16.verticalSpace,
                // NEW HABIT — white elevated card
                _UpgradeCard(
                  label: context.l10n.habit.upgradeNewLabel,
                  title: widget.newHabit.title.text,
                  skillsetId: widget.newHabit.skillsetId,
                  imageUrl: widget.newHabit.image,
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
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final String label;
  final String title;
  final String skillsetId;
  final String imageUrl;
  final bool highlighted;

  const _UpgradeCard({
    required this.label,
    required this.title,
    required this.skillsetId,
    required this.imageUrl,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          label,
          style: AppStyle.text12.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.1),
        ),
        if (highlighted) ...[
          16.verticalSpace,
          HabitDomainIcon(skillsetId: skillsetId, imageUrl: imageUrl, size: 48),
        ],
        highlighted ? 16.verticalSpace : 8.verticalSpace,
        AppText(
          title,
          textAlign: TextAlign.center,
          style: highlighted ? AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary) : AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
        ),
      ],
    );

    // The NEW-habit card's Default fill is plain white, so it can drop in as a
    // ThemedGlassCard (frosted over a custom background). The CURRENT-habit
    // card is tinted brandPrimary50, not white — swapping it would change the
    // Default look, so it keeps its own fixed Container instead.
    if (highlighted) {
      return SizedBox(
        width: double.infinity,
        child: ThemedGlassCard(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
          radius: 20,
          shadow: [BoxShadow(color: AppCustomColor.brandPrimary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
          child: content,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary50,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: content,
    );
  }
}
