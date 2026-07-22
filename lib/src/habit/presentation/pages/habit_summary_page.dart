part of '../../habit.dart';

/// Post-lesson "Weekly recap" (Figma "Weekly recap"): check-in arc gauge,
/// total-lessons/check-ins stats, a best-habit card, and per-category week
/// grids. Dismissed with Continue; the caller (KeypointCompletePage) continues
/// its own navigation afterwards.
class HabitSummaryPage extends StatefulWidget {
  const HabitSummaryPage({super.key});

  @override
  State<HabitSummaryPage> createState() => _HabitSummaryPageState();
}

class _HabitSummaryPageState extends State<HabitSummaryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent only when a custom study background is active.
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
      body: ThemedBackground(
        // Top-only safe area: the bottom CTA strip fills the home-indicator inset
        // itself (below) so the custom background never peeks under it.
        child: SafeBody(
          child: BlocBuilder<HabitCubit, HabitState>(
            builder: (context, state) {
              final summary = state.summary;
              final byGroup = <String, List<UserHabitEntity>>{};
              for (final userHabit in state.activeHabits) {
                byGroup.putIfAbsent(_habitGroupKey(userHabit), () => []).add(userHabit);
              }
              final categoryGroups = byGroup.values.toList();

              return Column(
                children: [
                  // Figma: a fixed 60-tall header, title + date range centered
                  // both ways (not just horizontally).
                  SizedBox(
                    height: 60.h,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            context.l10n.habit.summaryWeeklyReviewTitle,
                            style: AppStyle.textBold16.copyWith(color: studyThemeOnBg(context, AppCustomColor.textPrimary)),
                          ),
                          AppText(
                            _habitWeekRangeLabel(state.activeHabits),
                            // Figma text/tertiary is #5F6F86 (streakTextMuted here),
                            // not the app's lighter textTertiary token.
                            style: AppStyle.text12.copyWith(color: studyThemeOnBg(context, AppCustomColor.streakTextMuted)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Figma: the seedling glyph nestles INSIDE the arc's
                          // bottom gap (the gauge frame is clipped and the icon
                          // column overlaps it), not stacked below the gauge's
                          // square box — hence the Stack.
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                CircularPercentIndicator(
                                  radius: 93.w,
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
                                        // Figma: Mulish ExtraBold 36, line-height 1.25.
                                        style: AppStyle.textBold36.copyWith(
                                          // Bare on the background — lift the brand
                                          // purple to light lavender over a dark
                                          // custom bg so it stays readable.
                                          color: studyThemeAccentOnBg(context, AppCustomColor.brandPrimary),
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                        ),
                                      ),
                                      2.verticalSpace,
                                      AppText(
                                        context.l10n.habit.summaryCheckInRateLabel,
                                        style: AppStyle.text12.copyWith(color: studyThemeOnBg(context, AppCustomColor.streakTextMuted)),
                                      ),
                                    ],
                                  ),
                                ),
                                SvgPicture.asset('assets/svg/common/habit_summary_plant.svg', width: 24.w, height: 24.w),
                              ],
                            ),
                          ),
                          4.verticalSpace,
                          Center(child: _buildWorkingOnText(context, summary.activeCount)),
                          20.verticalSpace,
                          ThemedGlassCard(
                            solid: true,
                            padding: EdgeInsets.all(16.w),
                            radius: 12,
                            shadow: [BoxShadow(color: AppCustomColor.borderDefault, blurRadius: 2)],
                            // Figma: no divider between the two stat blocks.
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SummaryStatCell(
                                    label: context.l10n.habit.summaryTotalLessonsLabel,
                                    icon: Image.asset('assets/images/common/habit_summary_book.png', width: 24.w, height: 24.w),
                                    value: '${summary.totalLessons}',
                                  ),
                                ),
                                Expanded(
                                  child: _SummaryStatCell(
                                    label: context.l10n.habit.summaryTotalCheckInsLabel,
                                    icon: Image.asset('assets/images/common/habit_summary_calendar.png', width: 24.w, height: 24.w),
                                    value: '${summary.totalCheckIns}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          16.verticalSpace,
                          if (summary.bestHabit != null) ...[
                            _SummaryBestHabitCard(bestHabit: summary.bestHabit!),
                            20.verticalSpace,
                          ],
                          for (int i = 0; i < categoryGroups.length; i++) ...[
                            if (i > 0) 24.verticalSpace,
                            _SummaryCategoryCard(
                              title: _habitGroupTitle(categoryGroups[i].first, state),
                              userHabits: categoryGroups[i],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Figma "BottomCTA": a flat white strip, distinct from the
                  // gray page background — not just padding on the gray.
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 20.w + MediaQuery.paddingOf(context).bottom),
                    color: AppCustomColor.backgroundWhite,
                    child: DButton(
                      text: context.l10n.common.kContinue,
                      backgroundColor: AppCustomColor.brandPrimary,
                      size: Size(double.infinity, 54.h),
                      style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// "Jun 24–30" week label for the Weekly recap header, using the server week
/// start when present so the grids and the label agree on "this week".
String _habitWeekRangeLabel(List<UserHabitEntity> activeHabits) {
  final serverStart = activeHabits.map((h) => h.weekStartDate).whereType<DateTime>().firstOrNull;
  final now = DateTime.now();
  final start = serverStart ?? now.subtract(Duration(days: now.weekday - 1));
  final end = start.add(const Duration(days: 6));
  final startLabel = start.parseString('MMM d');
  final endLabel = start.month == end.month ? '${end.day}' : end.parseString('MMM d');
  // Figma: spaced en dash ("Jun 24 – 30").
  return '$startLabel – $endLabel';
}

/// "You're working on N habit(s)" (Figma): two-tone — the count phrase at the
/// end of the sentence in brand purple, everything before it in text/primary.
/// Both locale templates put the count at the end, so splitting there always
/// isolates exactly the phrase Figma highlights.
Widget _buildWorkingOnText(BuildContext context, int count) {
  final full = context.l10n.habit.summaryWorkingOnHabits(count: count);
  final base = AppStyle.textBold20;
  // Bare on the background (no card behind it) — the neutral portion swaps to
  // light ink over a dark custom bg; the brand-purple count phrase stays as-is.
  final baseColor = studyThemeOnBg(context, AppCustomColor.textPrimary);
  final markerIndex = full.indexOf('$count');
  if (markerIndex < 0) {
    return AppText(
      full,
      textAlign: TextAlign.center,
      style: base.copyWith(color: baseColor),
    );
  }
  return Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: full.substring(0, markerIndex),
          style: base.copyWith(color: baseColor),
        ),
        TextSpan(
          text: full.substring(markerIndex),
          style: base.copyWith(color: studyThemeAccentOnBg(context, AppCustomColor.streakActive)),
        ),
      ],
    ),
    textAlign: TextAlign.center,
  );
}

/// Weekly recap "Best habit" card (Figma): 🏆 label + loop length, then the
/// habit's title.
class _SummaryBestHabitCard extends StatelessWidget {
  final HabitBestHabitEntity bestHabit;

  const _SummaryBestHabitCard({required this.bestHabit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ThemedGlassCard(
        solid: true,
        padding: EdgeInsets.all(16.w),
        radius: 12,
        shadow: [BoxShadow(color: AppCustomColor.borderDefault, blurRadius: 2)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/common/habit_summary_trophy.png', width: 24.w, height: 24.w),
                8.horizontalSpace,
                Expanded(
                  child: AppText(
                    context.l10n.habit.summaryBestHabitLabel,
                    style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
                AppText(
                  context.l10n.habit.summaryBestHabitLoop(days: bestHabit.loop),
                  style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted),
                ),
              ],
            ),
            6.verticalSpace,
            // Indented to align under the label, past the icon + gap above.
            Padding(
              padding: EdgeInsets.only(left: 32.w),
              child: AppText(
                bestHabit.title.text,
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One category card in the Weekly recap (Figma "Weekly recap"): the category
/// ("problem") title, then each habit's title with its 7-day week grid.
class _SummaryCategoryCard extends StatelessWidget {
  final String title;
  final List<UserHabitEntity> userHabits;

  const _SummaryCategoryCard({required this.title, required this.userHabits});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ThemedGlassCard(
        solid: true,
        padding: EdgeInsets.all(16.w),
        radius: 12,
        shadow: [BoxShadow(color: AppCustomColor.borderDefault, blurRadius: 2)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppCustomColor.borderDefault)),
              ),
              child: AppText(
                title,
                style: AppStyle.text14.copyWith(color: AppCustomColor.streakTextMuted, fontWeight: FontWeight.w600),
              ),
            ),
            // Figma: rows just stack with padding — no divider between them.
            for (int i = 0; i < userHabits.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Figma item icon is the same 48px domain badge as the
                    // Today's-task rows, not a smaller 32 variant.
                    HabitDomainIcon(skillsetId: userHabits[i].habit?.skillsetId ?? '', size: 48),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            userHabits[i].displayTitle,
                            style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w600),
                          ),
                          8.verticalSpace,
                          HabitWeekGrid(weekGrid: userHabits[i].weekGrid),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatCell extends StatelessWidget {
  final String label;
  final Widget icon;
  final String value;

  const _SummaryStatCell({required this.label, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(label, style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted)),
        6.verticalSpace,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 24.w, height: 24.w, child: icon),
            8.horizontalSpace,
            AppText(value, style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary)),
          ],
        ),
      ],
    );
  }
}
