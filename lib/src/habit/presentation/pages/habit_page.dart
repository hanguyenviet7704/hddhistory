part of '../../habit.dart';

/// Tracker grouping key (§9.5 — "1 khóa = 1 cụm habit quanh 1 vấn đề"): group
/// by the course the habit was adopted from, falling back to its skillset for
/// legacy habits with no sourceCourseId.
String _habitGroupKey(UserHabitEntity h) => (h.sourceCourseId?.isNotEmpty ?? false) ? h.sourceCourseId! : (h.habit?.skillsetId ?? '');

/// Human title for a group: the course's title ("the problem"), else the
/// skillset title.
String _habitGroupTitle(UserHabitEntity h, HabitState state) {
  // §9.5: label the cluster with the re-anchor reason the user picked for this
  // course ("their why"). Prefer the value persisted on the habit at adopt
  // time; else the reason picked this session (remembered in state, so it
  // shows immediately after picking even for habits adopted earlier); else
  // fall back to the course title, then the skillset.
  final reason = h.reanchorReason.text;
  if (reason.isNotEmpty) return reason;
  final skillsets = AppDI.injector.get<HomeCubit>().state.skillsets;
  final courseId = h.sourceCourseId;
  if (courseId != null && courseId.isNotEmpty) {
    final picked = state.reanchorReasonByCourse[courseId]?.reason.text ?? '';
    if (picked.isNotEmpty) return picked;
    // Look up the course from the FULL catalog (HomeCubit.skillsets), not
    // ProgressCubit.myCourses — myCourses only carries courses with SAVED
    // progress, so it can still be stale/missing this exact course right
    // after adopting a habit from its very first keypoint, wrongly falling
    // all the way through to the bare skillset name below.
    final title = skillsets.resolveCourseByCourseId(courseId).title.text;
    if (title.isNotEmpty) return title;
  }
  final skillsetId = h.habit?.skillsetId ?? '';
  final skillset = skillsets.where((s) => s.id == skillsetId).firstOrNull;
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
  Future<void> _openDetail(UserHabitEntity userHabit) => HabitDetailPage.show(context, userHabit: userHabit);

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
        // Transparent only when a custom study background is active.
        backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
        // No top SafeArea: the green header scene paints edge-to-edge behind
        // the status bar (Figma "Today's task" — the status-bar strip is green,
        // not white). The scene reserves the top inset itself.
        body: BlocBuilder<HabitCubit, HabitState>(
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
    );
  }
}

// Green header scene (Figma node 10767:26104): the gradient's top colour, also
// used to fill the status-bar strip above the scene so they read as one piece.
const Color _kHabitHeaderTopGreen = Color(0xFFC7E0D2);

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
    // Only true once the user has picked a custom study background — gates the
    // green "nature" scene below: a custom photo/colour background wins and
    // the scene is skipped entirely so it can show through unobstructed. The
    // Default preset keeps the scene exactly as before.
    final isCustomBg = context.watch<StudyThemeCubit>().state.preset.isCustom;

    // The status-bar strip is part of the green scene (Figma): fill the top
    // inset with the scene's top gradient colour so it reads as one continuous
    // header instead of a white band above the green. On a custom background
    // that strip is transparent instead, so the background paints all the way
    // to the top of the screen.
    final topInset = MediaQuery.paddingOf(context).top;
    final statusBarCover = Container(width: double.infinity, height: topInset, color: isCustomBg ? Colors.transparent : _kHabitHeaderTopGreen);

    // Figma "Empty" (11418:15157): the green scene carries no title at all —
    // just the decorative backdrop — only when the user has never adopted a
    // habit. If they merely paused everything, "Today" keeps showing (with a
    // 0-tasks-left subtitle) instead of silently dropping the title.
    if (state.userHabits.isEmpty) {
      return Column(
        children: [
          statusBarCover,
          if (!isCustomBg) SizedBox(width: double.infinity, height: 140.h, child: const _HabitHeaderScene()),
        ],
      );
    }

    // Figma "Today's task" (10767:45771): the tracker header leads with "Today"
    // and the tasks-left count. There is no Task/Habit toggle — per-habit stats
    // live in the Habit detail screen.
    final title = context.l10n.habit.headerTodayTitle;
    final subtitle = context.l10n.habit.headerTasksToComplete(count: (state.activeCount - state.doneTodayCount).clamp(0, 999));

    return Column(
      children: [
        statusBarCover,
        SizedBox(
          width: double.infinity,
          height: 140.h,
          child: Stack(
            children: [
              if (!isCustomBg) const Positioned.fill(child: _HabitHeaderScene()),
              Positioned(
                left: 20.w,
                right: 20.w,
                bottom: 16.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(title, style: AppStyle.textBold24.copyWith(color: studyThemeOnBg(context, AppCustomColor.textPrimary))),
                    4.verticalSpace,
                    AppText(subtitle, style: AppStyle.text14.copyWith(color: studyThemeOnBg(context, AppCustomColor.streakTextMuted))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The green "nature" header backdrop from Figma (node 10767:26104): a
/// #c7e0d2 → #e5edc3 gradient with clouds + leafy hills, fading into the
/// gray body at the bottom so the title stays legible.
class _HabitHeaderScene extends StatelessWidget {
  const _HabitHeaderScene();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kHabitHeaderTopGreen, Color(0xFFE5EDC3)],
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
              AppText(context.l10n.habit.loadErrorTitle, style: AppStyle.text14.copyWith(color: studyThemeOnBg(context, AppCustomColor.textTertiary))),
              12.verticalSpace,
              DButton(
                text: context.l10n.habit.loadErrorRetryButton,
                backgroundColor: AppCustomColor.brandPrimary,
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
                onPressed: () => context.read<HabitCubit>().load(),
              ),
            ],
          ),
        ),
      );
    }

    // Genuinely empty (never adopted a habit) vs merely "everything paused" —
    // pausing all habits must not fall back to the "start your first habit"
    // empty state, or the user can never reach Edit Habit to resume one. The
    // category cards below still list only ACTIVE habits (today's checklist
    // has nothing to show when everything is paused) — Edit Habit remains
    // reachable either way to resume one.
    if (state.userHabits.isEmpty) {
      return SliverFillRemaining(child: HabitEmptyState(onGoToCourse: onGoToCourse));
    }

    final byGroup = <String, List<UserHabitEntity>>{};
    for (final userHabit in state.activeHabits) {
      byGroup.putIfAbsent(_habitGroupKey(userHabit), () => []).add(userHabit);
    }

    // Figma "Today's task": content lives on the soft-gray body (flush under the
    // green header), holding one white card per category (the "problem" a
    // cluster of habits addresses). Transparent only when a custom study
    // background is active, so it shows through instead of the flat gray.
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        width: double.infinity,
        color: studyThemeScaffoldColor(context, AppCustomColor.backgroundGray),
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 120.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            8.verticalSpace,
            ...byGroup.entries.map(
              (entry) => _HabitCategoryCard(
                title: _habitGroupTitle(entry.value.first, state),
                userHabits: entry.value,
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
                onTap: () {
                  AppHaptic.select();
                  onEdit();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 20.w, color: studyThemeOnBg(context, AppCustomColor.textQuaternary)),
                      8.horizontalSpace,
                      AppText(
                        context.l10n.habit.editHabitLink,
                        style: AppStyle.text14.copyWith(color: studyThemeOnBg(context, AppCustomColor.textQuaternary), fontWeight: FontWeight.w700),
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

/// One white category card (Figma "Today's task"): a muted category title with
/// a divider, then its habits as checklist rows.
class _HabitCategoryCard extends StatelessWidget {
  final String title;
  final List<UserHabitEntity> userHabits;
  final ValueChanged<UserHabitEntity> onCheckIn;
  final ValueChanged<UserHabitEntity> onOpenDetail;

  const _HabitCategoryCard({
    required this.title,
    required this.userHabits,
    required this.onCheckIn,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
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
            // Figma "Today's task": task rows stack with no divider between
            // them — only the category header keeps its bottom border.
            for (final userHabit in userHabits)
              HabitTaskRow(
                userHabit: userHabit,
                onCheckInTap: () => onCheckIn(userHabit),
                onOpenDetail: () => onOpenDetail(userHabit),
              ),
          ],
        ),
      ),
    );
  }
}
