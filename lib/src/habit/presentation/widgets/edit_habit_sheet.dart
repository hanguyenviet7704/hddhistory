part of '../../habit.dart';

/// All-habits edit sheet (Figma 10767:45181 / 10783:46990): habits grouped
/// into Active / Inactive with a switch per row; "Remove" at the top switches
/// the trailing control to a delete button. Resuming a paused habit can hit
/// the slot limit — that pops this sheet and hands off to
/// [SlotFullUpgradeSheet].
class EditHabitSheet extends StatefulWidget {
  const EditHabitSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // The sheet lives under the root navigator, outside the page's provider
      // scope — resolve the singleton cubit from DI instead.
      builder: (_) => BlocProvider.value(
        value: AppDI.injector.get<HabitCubit>(),
        child: const EditHabitSheet(),
      ),
    );
  }

  @override
  State<EditHabitSheet> createState() => _EditHabitSheetState();
}

// Figma 10767:45181 active-row tint — a border shade between backgroundBrand
// and backgroundBrandSoft that doesn't have its own app-wide token yet.
const Color _kEditActiveRowBorder = Color(0xFFE0DEFD);

class _EditHabitSheetState extends State<EditHabitSheet> {
  bool _removeMode = false;

  Future<void> _toggleActive(UserHabitEntity userHabit, bool active) async {
    final cubit = context.read<HabitCubit>();
    final result = await cubit.setActive(userHabit.id, active);
    if (!mounted) return;
    if (result == AdoptHabitResult.slotFull) {
      Navigator.of(context).pop();
      SlotFullUpgradeSheet.show(context, pendingHabitTitle: userHabit.displayTitle);
    }
  }

  Future<void> _remove(UserHabitEntity userHabit) async {
    await context.read<HabitCubit>().remove(userHabit.id);
  }

  Widget _buildSection(BuildContext context, String label, List<UserHabitEntity> items, {required bool isActive}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText(
              label,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary, fontWeight: FontWeight.w700),
            ),
            6.horizontalSpace,
            AppText(
              '${items.length}',
              style: AppStyle.text14.copyWith(color: AppCustomColor.textQuaternary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        12.verticalSpace,
        ...items.map((userHabit) => _buildRow(context, userHabit, isActive: isActive)),
        8.verticalSpace,
      ],
    );
  }

  Widget _buildRow(BuildContext context, UserHabitEntity userHabit, {required bool isActive}) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isActive ? AppCustomColor.backgroundBrandSoft : AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isActive ? _kEditActiveRowBorder : AppCustomColor.borderDefault),
      ),
      child: Row(
        children: [
          HabitDomainIcon(skillsetId: userHabit.habit?.skillsetId ?? '', fallbackEmoji: userHabit.displayIcon, size: 48),
          12.horizontalSpace,
          Expanded(
            child: AppText(
              userHabit.displayTitle,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          8.horizontalSpace,
          if (_removeMode)
            Semantics(
              button: true,
              label: context.l10n.habit.editRemoveLink,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.remove_circle_outline, color: AppCustomColor.errorRed, size: 24.w),
                onPressed: () => _remove(userHabit),
              ),
            )
          else
            Switch(
              value: userHabit.isActive,
              activeTrackColor: AppCustomColor.brandPrimary,
              onChanged: (value) => _toggleActive(userHabit, value),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(20.w),
        constraints: BoxConstraints(maxHeight: 0.85.sh),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: BlocBuilder<HabitCubit, HabitState>(
          builder: (context, state) {
            final active = state.userHabits.where((h) => h.isActive).toList();
            final inactive = state.userHabits.where((h) => !h.isActive).toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        context.l10n.habit.editSheetTitle,
                        style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: _removeMode ? context.l10n.habit.editDoneButton : context.l10n.habit.editRemoveLink,
                      child: TextButton(
                        onPressed: () => setState(() => _removeMode = !_removeMode),
                        child: AppText(
                          _removeMode ? context.l10n.habit.editDoneButton : context.l10n.habit.editRemoveLink,
                          style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: context.l10n.common.close,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.close, size: 24.w, color: AppCustomColor.textTertiary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                16.verticalSpace,
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(context, context.l10n.habit.editActiveLabel, active, isActive: true),
                        _buildSection(context, context.l10n.habit.editInactiveLabel, inactive, isActive: false),
                      ],
                    ),
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
