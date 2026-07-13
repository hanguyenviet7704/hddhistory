part of '../../habit.dart';

/// All-habits edit sheet (Figma 10767:45181 / 10783:46990): habits grouped
/// into Active / Inactive with a switch per row — toggle on/off only, habits
/// are never deleted from here (pausing keeps their history). Resuming a
/// paused habit can hit the slot limit — that pops this sheet and hands off
/// to [SlotFullUpgradeSheet].
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
  // Per-row busy tracking (a single bool would disable every row while only
  // one is in flight) — blocks re-tap on that row and shows its spinner.
  final Set<String> _togglingIds = {};

  Future<void> _toggleActive(UserHabitEntity userHabit, bool active) async {
    setState(() => _togglingIds.add(userHabit.id));
    final cubit = context.read<HabitCubit>();
    try {
      final result = await cubit.setActive(userHabit.id, active);
      if (!mounted) return;
      switch (result) {
        case AdoptHabitResult.slotFull:
          Navigator.of(context).pop();
          SlotFullUpgradeSheet.show(context, pendingHabitTitle: userHabit.displayTitle);
        case AdoptHabitResult.failure:
          context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
        case AdoptHabitResult.success:
          break;
      }
    } finally {
      if (mounted) setState(() => _togglingIds.remove(userHabit.id));
    }
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
          HabitDomainIcon(skillsetId: userHabit.habit?.skillsetId ?? '', size: 48),
          12.horizontalSpace,
          Expanded(
            child: AppText(
              userHabit.displayTitle,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          8.horizontalSpace,
          HabitSwitch(
            value: userHabit.isActive,
            onChanged: (value) => _toggleActive(userHabit, value),
            isLoading: _togglingIds.contains(userHabit.id),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bake the bottom safe-area inset into the container's own padding
    // instead of wrapping in SafeArea — that keeps the white sheet flush to
    // the bottom edge (no transparent gap showing under it) while content
    // still clears the home indicator / Android nav bar.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 20.w + bottomInset),
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
    );
  }
}
