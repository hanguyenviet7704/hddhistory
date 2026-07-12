part of '../../habit.dart';

/// Post-lesson "Weekly review" (Figma 11035:27501, design.md 5.4): check-in
/// arc gauge, streak/check-in stats, per-category week grids, and the
/// recommit ("How far this time?") prompt. Pops when dismissed either way;
/// the caller (KeypointCompletePage) continues its own navigation afterwards
/// regardless of the choice made here.
class HabitSummaryPage extends StatefulWidget {
  const HabitSummaryPage({super.key});

  @override
  State<HabitSummaryPage> createState() => _HabitSummaryPageState();
}

class _HabitSummaryPageState extends State<HabitSummaryPage> {
  static const List<int> _packOptions = [3, 7, 14];
  int _selectedPackLength = 7;
  bool _isSubmitting = false;

  Future<void> _startPack(HabitState state) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final cubit = context.read<HabitCubit>();
    for (final userHabit in state.activeHabits) {
      await cubit.setPackLength(userHabit.id, _selectedPackLength);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: SafeBody(
        child: BlocBuilder<HabitCubit, HabitState>(
          builder: (context, state) {
            final summary = state.summary;
            final byGroup = <String, List<UserHabitEntity>>{};
            for (final userHabit in state.activeHabits) {
              byGroup.putIfAbsent(_habitGroupKey(userHabit), () => []).add(userHabit);
            }

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 8.w, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: [
                          AppText(
                            context.l10n.habit.summaryWeeklyReviewTitle,
                            style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
                          ),
                          2.verticalSpace,
                          AppText(
                            _habitWeekRangeLabel(state.activeHabits),
                            style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          button: true,
                          label: context.l10n.common.close,
                          child: IconButton(
                            icon: Icon(Icons.close, size: 24.w, color: AppCustomColor.textTertiary),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircularPercentIndicator(
                            radius: 80.w,
                            lineWidth: 14.w,
                            percent: (summary.checkInRate / 100).clamp(0, 1),
                            arcType: ArcType.FULL,
                            arcBackgroundColor: AppCustomColor.brandPrimary50,
                            backgroundColor: Colors.transparent,
                            progressColor: AppCustomColor.brandPrimary,
                            circularStrokeCap: CircularStrokeCap.round,
                            animateFromLastPercent: true,
                            animation: true,
                            animationDuration: 500,
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText(
                                  '${summary.checkInRate}%',
                                  style: AppStyle.textBold28.copyWith(color: AppCustomColor.brandPrimary),
                                ),
                                2.verticalSpace,
                                AppText(
                                  context.l10n.habit.summaryCheckInRateLabel,
                                  style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        8.verticalSpace,
                        Center(
                          child: AppText(
                            context.l10n.habit.summaryWorkingOnHabits(count: summary.activeCount),
                            style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
                          ),
                        ),
                        20.verticalSpace,
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: AppCustomColor.backgroundWhite,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SummaryStatCell(
                                    label: context.l10n.habit.summaryBestStreakLabel,
                                    icon: '🔥',
                                    value: context.l10n.habit.summaryBestStreakValue(days: summary.bestStreak),
                                  ),
                                ),
                                VerticalDivider(width: 1, color: AppCustomColor.borderDefault),
                                Expanded(
                                  child: _SummaryStatCell(
                                    label: context.l10n.habit.summaryTotalCheckInsLabel,
                                    icon: '📅',
                                    value: '${summary.totalCheckIns}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        20.verticalSpace,
                        ...byGroup.entries.map(
                          (entry) => _HabitCategoryCard(
                            title: _habitGroupTitle(entry.value.first),
                            userHabits: entry.value,
                            isTaskView: false,
                            onCheckIn: (_) {},
                            onOpenDetail: (_) {},
                          ),
                        ),
                        if (state.activeHabits.isNotEmpty) ...[
                          12.verticalSpace,
                          AppText(
                            context.l10n.habit.summaryCommitmentQuestion,
                            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
                          ),
                          12.verticalSpace,
                          Row(
                            children: _packOptions.map((days) {
                              final selected = _selectedPackLength == days;
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: Semantics(
                                  button: true,
                                  selected: selected,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(1000.r),
                                    onTap: () => setState(() => _selectedPackLength = days),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                      decoration: BoxDecoration(
                                        color: selected ? AppCustomColor.brandPrimary : AppCustomColor.backgroundWhite,
                                        borderRadius: BorderRadius.circular(1000.r),
                                        border: Border.all(
                                          color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
                                        ),
                                      ),
                                      child: AppText(
                                        '$days',
                                        style: AppStyle.text14.copyWith(
                                          color: selected ? AppCustomColor.textWhite : AppCustomColor.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.activeHabits.isNotEmpty) ...[
                        DButton(
                          text: context.l10n.habit.summaryCommitmentStartButton(days: _selectedPackLength),
                          onPressed: _isSubmitting ? null : () => _startPack(state),
                        ),
                        4.verticalSpace,
                        DButton(
                          text: context.l10n.habit.summaryCommitmentMaybeLater,
                          buttonType: DButtonType.text,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ] else
                        DButton(
                          text: context.l10n.common.kContinue,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
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

class _SummaryStatCell extends StatelessWidget {
  final String label;
  final String icon;
  final String value;

  const _SummaryStatCell({required this.label, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(label, style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary)),
        6.verticalSpace,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(icon, style: AppStyle.text16),
            6.horizontalSpace,
            AppText(value, style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary)),
          ],
        ),
      ],
    );
  }
}
