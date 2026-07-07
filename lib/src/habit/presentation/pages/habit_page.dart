part of '../../habit.dart';

/// "Jun 1–7" style label for the current week (Figma Habit view + Weekly
/// review). Uses the server-provided week start when available so the grids
/// and the label always agree on what "this week" means.
String _habitWeekRangeLabel(List<UserHabitEntity> activeHabits) {
  final serverStart = activeHabits.map((h) => h.weekStartDate).whereType<DateTime>().firstOrNull;
  final now = DateTime.now();
  final start = serverStart ?? now.subtract(Duration(days: now.weekday - 1));
  final end = start.add(const Duration(days: 6));
  final startLabel = start.parseString('MMM d');
  final endLabel = start.month == end.month ? '${end.day}' : end.parseString('MMM d');
  return '$startLabel–$endLabel';
}

/// Tracker grouping key (§9.5 — "1 khóa = 1 cụm habit quanh 1 vấn đề"): group
/// by the course the habit was adopted from, falling back to its skillset for
/// legacy habits with no sourceCourseId.
String _habitGroupKey(UserHabitEntity h) =>
    (h.sourceCourseId?.isNotEmpty ?? false) ? h.sourceCourseId! : (h.habit?.skillsetId ?? '');

/// Human title for a group: the course's title ("the problem"), else the
/// skillset title.
String _habitGroupTitle(UserHabitEntity h) {
  final courseId = h.sourceCourseId;
  if (courseId != null && courseId.isNotEmpty) {
    final course = AppDI.injector.get<ProgressCubit>().state.myCourses.where((c) => c.id == courseId).firstOrNull;
    final title = course?.title.text ?? '';
    if (title.isNotEmpty) return title;
  }
  final skillsetId = h.habit?.skillsetId ?? '';
  final skillset = AppDI.injector.get<HomeCubit>().state.skillsets.where((s) => s.id == skillsetId).firstOrNull;
  return skillset?.title.text ?? '';
}

class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Recover from a failed/skipped first load, same self-heal shape as
      // HomeCubit.ensureHomeDataLoaded — no-op when data is already present.
      unawaited(context.read<HabitCubit>().ensureLoaded());
    });
  }

  /// Tap the check circle → check-in + diary sheet (PRD §9.7). Refreshes the
  /// tracker afterwards so the tick + counts update.
  Future<void> _openCheckIn(UserHabitEntity userHabit) async {
    final done = await CheckInDiarySheet.show(context, userHabit: userHabit);
    if (done == true && mounted) {
      unawaited(context.read<HabitCubit>().load(showLoading: false));
    }
  }

  /// Tap the habit row → Habit detail (PRD §9.8).
  Future<void> _openDetail(UserHabitEntity userHabit) => HabitDetailPage.push(context, userHabit: userHabit);

  /// Empty state "Go to course" → Explore tab (PRD §9.5): habits are created
  /// from lessons, so a user with none is sent to browse courses.
  void _goToCourse() {
    context.read<PageCubit>().setCurrentIndex(3);
    CourseRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
      listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
      listener: (context, state) {
        // Returning to this tab with nothing loaded (initial retry also
        // failed) -> try again.
        unawaited(context.read<HabitCubit>().ensureLoaded());
      },
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundGray,
        body: SafeBody(
          child: BlocBuilder<HabitCubit, HabitState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () => context.read<HabitCubit>().load(showLoading: false),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _HabitHeader(state: state)),
                    _HabitBody(
                      state: state,
                      onCheckIn: _openCheckIn,
                      onOpenDetail: _openDetail,
                      onEdit: () => EditHabitSheet.show(context),
                      onGoToCourse: _goToCourse,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Header illustration assets (Figma node 10767:26104 — green "nature" scene).
const String _kHabitCloudSmall = 'assets/svg/common/habit_header_cloud_small.svg';
const String _kHabitCloudBig = 'assets/svg/common/habit_header_cloud_big.svg';
const String _kHabitHill = 'assets/svg/common/habit_header_hill.svg';
const String _kHabitBushLeft = 'assets/svg/common/habit_header_bush_left.svg';
const String _kHabitBushRight = 'assets/svg/common/habit_header_bush_right.svg';

class _HabitHeader extends StatelessWidget {
  final HabitState state;

  const _HabitHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final isTaskView = state.toggle == HabitTabToggle.task;
    final allDone = state.allDoneToday;

    // Per Figma: Task view leads with "Today"/tasks-left, Habit view with the
    // done/total counter.
    final title = isTaskView
        ? context.l10n.habit.headerTodayTitle
        : context.l10n.habit.headerCompletedTitle(done: state.doneTodayCount, total: state.activeCount);
    final subtitle = isTaskView
        ? context.l10n.habit.headerTasksToComplete(count: (state.activeCount - state.doneTodayCount).clamp(0, 999))
        : state.userHabits.isEmpty
            ? context.l10n.habit.headerEmptySubtitle
            : allDone
                ? context.l10n.habit.headerAllDoneSubtitle
                : context.l10n.habit.headerInProgressSubtitle;

    return SizedBox(
      width: double.infinity,
      height: 140.h,
      child: Stack(
        children: [
          const Positioned.fill(child: _HabitHeaderScene()),
          Positioned(
            left: 20.w,
            right: 20.w,
            bottom: 16.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(title, style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary)),
                      4.verticalSpace,
                      AppText(subtitle, style: AppStyle.text14.copyWith(color: AppCustomColor.streakTextMuted)),
                    ],
                  ),
                ),
                // The Habit view places the toggle inside the sheet next to the
                // week range (see _HabitBody) — Task view keeps it up here.
                if (isTaskView) _ToggleTabs(toggle: state.toggle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The green "nature" header backdrop from Figma (node 10767:26104): a
/// #c7e0d2 → #e5edc3 gradient with clouds + leafy hills, fading into the
/// gray body at the bottom so the title/toggle stay legible.
class _HabitHeaderScene extends StatelessWidget {
  const _HabitHeaderScene();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC7E0D2), Color(0xFFE5EDC3)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -16.w,
            top: 3.h,
            width: 51.51.w,
            height: 35.48.h,
            child: SvgPicture.asset(_kHabitCloudSmall, fit: BoxFit.contain),
          ),
          Positioned(
            left: 265.w,
            top: 20.h,
            width: 68.56.w,
            height: 41.39.h,
            child: SvgPicture.asset(_kHabitCloudBig, fit: BoxFit.contain),
          ),
          Positioned(
            left: -18.w,
            top: 69.h,
            width: 411.55.w,
            height: 101.5.h,
            child: SvgPicture.asset(_kHabitHill, fit: BoxFit.fill),
          ),
          Positioned(
            left: -28.w,
            top: 80.h,
            width: 99.41.w,
            height: 82.75.h,
            child: SvgPicture.asset(_kHabitBushLeft, fit: BoxFit.contain),
          ),
          Positioned(
            left: 309.w,
            top: 80.h,
            width: 98.65.w,
            height: 82.75.h,
            child: SvgPicture.asset(_kHabitBushRight, fit: BoxFit.contain),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 56.h,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppCustomColor.backgroundGray.withValues(alpha: 0),
                    AppCustomColor.backgroundGray,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTabs extends StatelessWidget {
  final HabitTabToggle toggle;

  const _ToggleTabs({required this.toggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleTabButton(
            label: context.l10n.habit.taskToggleLabel,
            selected: toggle == HabitTabToggle.task,
            onTap: () => context.read<HabitCubit>().setToggle(HabitTabToggle.task),
          ),
          _ToggleTabButton(
            label: context.l10n.habit.habitToggleLabel,
            selected: toggle == HabitTabToggle.habit,
            onTap: () => context.read<HabitCubit>().setToggle(HabitTabToggle.habit),
          ),
        ],
      ),
    );
  }
}

class _ToggleTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Figma: selected segment is a white pill with dark bold text on a soft
    // lavender track (not a filled-brand pill).
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(1000.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: selected ? AppCustomColor.backgroundWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(1000.r),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppCustomColor.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: AppText(
            label,
            style: AppStyle.text14.copyWith(
              color: selected ? AppCustomColor.textPrimary : AppCustomColor.textTertiary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitBody extends StatelessWidget {
  final HabitState state;
  final ValueChanged<UserHabitEntity> onCheckIn;
  final ValueChanged<UserHabitEntity> onOpenDetail;
  final VoidCallback onEdit;
  final VoidCallback onGoToCourse;

  const _HabitBody({
    required this.state,
    required this.onCheckIn,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onGoToCourse,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == HabitPageStatus.loading && state.userHabits.isEmpty) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }

    if (state.status == HabitPageStatus.failure && state.userHabits.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(context.l10n.habit.loadErrorTitle, style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary)),
              12.verticalSpace,
              DButton(
                text: context.l10n.habit.loadErrorRetryButton,
                onPressed: () => context.read<HabitCubit>().load(),
              ),
            ],
          ),
        ),
      );
    }

    if (state.activeHabits.isEmpty) {
      return SliverFillRemaining(child: HabitEmptyState(onGoToCourse: onGoToCourse));
    }

    final byGroup = <String, List<UserHabitEntity>>{};
    for (final userHabit in state.activeHabits) {
      byGroup.putIfAbsent(_habitGroupKey(userHabit), () => []).add(userHabit);
    }
    final isTaskView = state.toggle == HabitTabToggle.task;

    // Figma: content lives on the soft-gray body (flush under the green
    // header), holding one white card per category.
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        width: double.infinity,
        color: AppCustomColor.backgroundGray,
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 120.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            8.verticalSpace,
            if (!isTaskView) ...[
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      _habitWeekRangeLabel(state.activeHabits),
                      style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
                    ),
                  ),
                  _ToggleTabs(toggle: state.toggle),
                ],
              ),
              16.verticalSpace,
            ],
            ...byGroup.entries.map(
              (entry) => _HabitCategoryCard(
                title: _habitGroupTitle(entry.value.first),
                userHabits: entry.value,
                isTaskView: isTaskView,
                onCheckIn: onCheckIn,
                onOpenDetail: onOpenDetail,
              ),
            ),
            4.verticalSpace,
            Semantics(
              button: true,
              label: context.l10n.habit.editHabitLink,
              child: InkWell(
                borderRadius: BorderRadius.circular(8.r),
                onTap: onEdit,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 16.w, color: AppCustomColor.textTertiary),
                      6.horizontalSpace,
                      AppText(
                        context.l10n.habit.editHabitLink,
                        style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One white category card (Figma): category title + its habits, rendered as
/// checklist rows (Task view) or week-grid rows (Habit view).
class _HabitCategoryCard extends StatelessWidget {
  final String title;
  final List<UserHabitEntity> userHabits;
  final bool isTaskView;
  final ValueChanged<UserHabitEntity> onCheckIn;
  final ValueChanged<UserHabitEntity> onOpenDetail;

  const _HabitCategoryCard({
    required this.title,
    required this.userHabits,
    required this.isTaskView,
    required this.onCheckIn,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: AppCustomColor.borderDefault, blurRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppCustomColor.borderDefault)),
            ),
            child: Row(
              children: [
                Flexible(
                  child: AppText(
                    title,
                    style: isTaskView
                        ? AppStyle.text14.copyWith(color: AppCustomColor.streakTextMuted, fontWeight: FontWeight.w600)
                        : AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
                  ),
                ),
                if (!isTaskView) ...[
                  8.horizontalSpace,
                  AppText('${userHabits.length}', style: AppStyle.text14.copyWith(color: AppCustomColor.streakTextMuted)),
                ],
              ],
            ),
          ),
          for (int index = 0; index < userHabits.length; index++) ...[
            if (index > 0) Divider(height: 1, color: AppCustomColor.borderDefault),
            if (isTaskView)
              HabitTaskRow(
                userHabit: userHabits[index],
                onCheckInTap: () => onCheckIn(userHabits[index]),
                onOpenDetail: () => onOpenDetail(userHabits[index]),
              )
            else
              _HabitWeeklyRow(
                userHabit: userHabits[index],
                onOpenDetail: () => onOpenDetail(userHabits[index]),
              ),
          ],
        ],
      ),
    );
  }
}

class _HabitWeeklyRow extends StatelessWidget {
  final UserHabitEntity userHabit;
  final VoidCallback onOpenDetail;

  const _HabitWeeklyRow({required this.userHabit, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpenDetail,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HabitDomainIcon(skillsetId: userHabit.habit?.skillsetId ?? '', fallbackEmoji: userHabit.displayIcon),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(userHabit.displayTitle, style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary)),
                  8.verticalSpace,
                  HabitWeekGrid(weekGrid: userHabit.weekGrid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
