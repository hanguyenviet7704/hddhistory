part of '../../home.dart';

/// The three progress blocks that moved from the Profile tab onto Home
/// (design note 2026-09-04): "Tiến độ", "Nhật ký học tập" and "Tiến độ học tập".
///
/// They moved because Profile stopped being a tab: what is left of it is a
/// Settings screen behind the header gear, and a reader is not going to open
/// Settings to see whether they studied yesterday. Everything here is
/// display-only — the streak card no longer opens a detail page, because the
/// detail it used to open is now the card itself.

/// Muted secondary text/icon colour (design #9AA4B2).
const Color _homeMutedTextColor = Color(0xFF9AA4B2);

/// Progress-bar track colour for the learning-progress rows (design #E7E9F2).
const Color _homeProgressTrackColor = Color(0xFFE7E9F2);

/// Rotating pastel tint palette for the learning-progress icon tiles — the API
/// has no per-category colour, so tiles cycle through a small set of existing
/// soft theme tokens for variety instead of one flat tint everywhere.
const List<Color> _homeCategoryTints = [
  AppCustomColor.backgroundBrandSoft,
  AppCustomColor.backgroundError,
  AppCustomColor.backgroundSuccess,
  AppCustomColor.brandPrimary50,
  AppCustomColor.backgroundGray,
  AppCustomColor.surfaceMuted,
];

/// Inlined design icons (verbatim from the design SVGs) so they match 1:1
/// without an asset-bundle rebuild.
const String _kHomeStreakGraySvg =
    '''<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6.40039 19.4798C6.40039 25.6687 11.7915 28 16.9462 28C21.959 28 25.6004 23.1179 25.6004 18.7426C25.6004 12.1567 19.2634 3.77267 16.4733 4.00471C13.5413 4.32689 15.0073 10.8672 13.5413 11.1435C12.7373 11.3736 12.8792 8.50939 11.4605 8.28833C10.2782 8.10411 6.40039 11.6964 6.40039 19.4798Z" fill="#DDE3EB"></path><path d="M12.9023 21.2009C12.9023 23.094 14.6995 24.4395 16.4706 24.4395C18.1874 24.4395 19.3023 22.6378 19.3023 21.2009C19.3023 19.0381 17.3978 16.4395 16.1517 16.4395C14.7904 16.4395 12.9023 19.4312 12.9023 21.2009Z" fill="#AAB8CD"></path></svg>''';
const String _kHomeClockSvg =
    '''<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg"><g clip-path="url(#clip0_6577_16697)"><path opacity="0.4" d="M16 28C18.3578 28 20.5375 27.2219 22.2906 25.9094L23.9406 27.5594C24.5266 28.1453 25.4781 28.1453 26.0641 27.5594C26.65 26.9734 26.65 26.0219 26.0641 25.4359L24.4141 23.7859C25.7266 22.0328 26.5047 19.8578 26.5047 17.4953C26.5 11.7016 21.7984 7 16 7C10.2016 7 5.5 11.7016 5.5 17.5C5.5 19.8578 6.27812 22.0375 7.59062 23.7906L5.94063 25.4406C5.35469 26.0266 5.35469 26.9781 5.94063 27.5641C6.52656 28.15 7.47812 28.15 8.06406 27.5641L9.71406 25.9141C11.4672 27.2266 13.6422 28.0047 16 28.0047V28ZM17.125 12.625V17.0359L19.0469 18.9578C19.4875 19.3984 19.4875 20.1109 19.0469 20.5469C18.6062 20.9828 17.8938 20.9875 17.4578 20.5469L15.2078 18.2969C14.9969 18.0859 14.8797 17.8 14.8797 17.5V12.625C14.8797 12.0016 15.3813 11.5 16.0047 11.5C16.6281 11.5 17.1297 12.0016 17.1297 12.625H17.125Z" fill="#AAB8CD"></path><path d="M4.69844 10.8625L11.5 5.19062C10.7031 4.45 9.63437 4 8.4625 4C5.99687 4 4 5.99687 4 8.4625C4 9.34375 4.25781 10.1641 4.69844 10.8578V10.8625ZM16 11.5C15.3766 11.5 14.875 12.0016 14.875 12.625V17.5C14.875 17.8 14.9922 18.0859 15.2031 18.2969L17.4531 20.5469C17.8938 20.9875 18.6062 20.9875 19.0422 20.5469C19.4781 20.1062 19.4828 19.3937 19.0422 18.9578L17.1203 17.0359V12.625C17.1203 12.0016 16.6187 11.5 15.9953 11.5H16ZM20.5 5.19062L27.3016 10.8625C27.7422 10.1687 28 9.34375 28 8.4625C28 5.99687 26.0031 4 23.5375 4C22.3656 4 21.2969 4.45 20.5 5.19062Z" fill="#AAB8CD"></path></g><defs><clipPath id="clip0_6577_16697"><rect width="24" height="24" fill="white" transform="translate(4 4)"></rect></clipPath></defs></svg>''';

/// One of Home's section headings ("Gợi ý cho bạn", "Tiến độ", …).
///
/// 15.5/700, down from the 18-20 these ran at before: the redesign has five
/// headings on one page where the old Home had two, and at 18 they read as
/// five competing titles rather than as the page's outline.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.title, {super.key, this.topGap = 28});

  final String title;

  /// Space above the heading. The design runs a uniform `margin:28px 0 12px`
  /// on every one of these; the first heading on the page passes 0 because the
  /// block above it already paid its own bottom gap.
  final double topGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, topGap.h, 20.w, 12.h),
      child: AppText(
        title,
        style: TextStyle(
          fontFamily: AppFont.mulish,
          fontSize: 15.5.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: studyThemeOnBg(context, AppCustomColor.textPrimary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Tiến độ" — the streak card and the two stat tiles under it
// ---------------------------------------------------------------------------

/// Streak week + best-streak/minutes tiles.
///
/// The design tightened this block against its own card edges ("nhìn gọn hơn")
/// and dropped the bold numbers a size or two: 24→20 for "Chuỗi N ngày", 19→18
/// for the two tile values. The card padding came in with them (18/18/16 →
/// 14/16/12), which is what actually does the tightening — the numbers only
/// looked oversized because they were floating in a roomy card.
class HomeStreakSection extends StatelessWidget {
  const HomeStreakSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningStreakCubit, LearningStreakState>(
      bloc: AppDI.injector.get<LearningStreakCubit>(),
      builder: (context, state) {
        final streak = state.selectedItem;
        final label = context.l10n.learningStreak.streakDays(count: streak.currentStreak);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionTitle(context.l10n.setting.settingProfileProgressSection),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  Semantics(
                    label: label,
                    child: ThemedGlassCard(
                      key: const Key('home-streak-card'),
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
                      radius: 20,
                      shadow: _homeCardShadow,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 26.w,
                                height: 30.h,
                                child: SvgPicture.asset(AppAsset.svg.app.icFlameActive, fit: BoxFit.contain),
                              ),
                              9.horizontalSpace,
                              AppText(label, style: _poppins(20, FontWeight.w700)),
                            ],
                          ),
                          12.verticalSpace,
                          StreakWeekBar(weekStudy: streak.normalizedWeekStudy),
                        ],
                      ),
                    ),
                  ),
                  10.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _HomeStatCard(
                          icon: _kHomeStreakGraySvg,
                          value: context.l10n.learningStreak.daysShort(count: streak.bestStreak),
                          label: context.l10n.learningStreak.bestStreakLabel,
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: _HomeStatCard(
                          icon: _kHomeClockSvg,
                          value: context.l10n.learningStreak.minutesShort(count: streak.studyTime),
                          label: context.l10n.learningStreak.thisWeekLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({required this.icon, required this.value, required this.label});

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ThemedGlassCard(
      padding: EdgeInsets.all(13.w),
      radius: 18,
      shadow: _homeCardShadow,
      child: Row(
        children: [
          SvgPicture.string(icon, width: 30.w, height: 30.w, fit: BoxFit.contain),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  value,
                  maxLines: 1,
                  // Shrink-to-fit so a longer value (e.g. "141 phút") isn't
                  // clipped to "141 ph…" in this narrow half-width card.
                  enableFitScaleDown: true,
                  style: _poppins(18, FontWeight.w700),
                ),
                AppText(
                  label,
                  maxLines: 1,
                  // Same reason, for a longer label ("Chuỗi dài nhất"), while
                  // keeping both tiles a single line and equal height.
                  enableFitScaleDown: true,
                  style: AppStyle.text12.copyWith(color: studyThemeCardMuted(context, _homeMutedTextColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Nhật ký học tập" — the month heat-map
// ---------------------------------------------------------------------------

class HomeJournalSection extends StatelessWidget {
  const HomeJournalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionTitle(context.l10n.studyJournal.sectionTitle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: const StudyJournalCalendar(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Tiến độ học tập" — one tile per category, two to a row
// ---------------------------------------------------------------------------

/// Per-category progress, redrawn as a two-column grid inside ONE card.
///
/// It used to be a full-width list of rows with dividers and a chevron each.
/// Six of those made a very tall block for what is really a glanceable summary,
/// so the design halved the width, dropped the chevrons and the dividers, and
/// let the tiles pack two to a row (design `HDDhistory Home (standalone)`).
class HomeLearningProgressSection extends StatelessWidget {
  const HomeLearningProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AchievenmentProgressCubit, AchievenmentProgressState>(
      buildWhen: (previous, current) => previous.achievenments != current.achievenments,
      builder: (context, state) {
        final visible = state.achievenments.where((a) => a.totalCourse > 0).toList();
        // No category started yet: nothing to be at 0% about. The section is
        // absent rather than empty — an empty progress card would read as a
        // loading failure.
        if (visible.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionTitle(context.l10n.setting.settingProfileLearningProgressSection),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: ThemedGlassCard(
                padding: EdgeInsets.all(12.w),
                radius: 20,
                shadow: _homeCardShadow,
                // The progress denominator is the category's whole catalog size,
                // which lives in HomeCubit — rebuild when it arrives so the bars
                // aren't stuck on the (much smaller) achievement fallback if
                // categories load late.
                child: BlocBuilder<HomeCubit, HomeState>(
                  buildWhen: (prev, curr) => prev.categories != curr.categories,
                  builder: (context, homeState) {
                    return Column(
                      children: [
                        for (int i = 0; i < visible.length; i += 2)
                          Padding(
                            // Design `gap:6px 4px` — the row gap, paid by every
                            // row but the last.
                            padding: EdgeInsets.only(bottom: i + 2 < visible.length ? 6.h : 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _HomeCategoryTile(achievement: visible[i], homeState: homeState, tint: _tint(i))),
                                4.horizontalSpace,
                                // An odd count leaves the last slot empty rather
                                // than letting one tile stretch to full width —
                                // a lone double-wide bar would read as a
                                // different, more important row.
                                Expanded(
                                  child: i + 1 < visible.length
                                      ? _HomeCategoryTile(achievement: visible[i + 1], homeState: homeState, tint: _tint(i + 1))
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _tint(int index) => _homeCategoryTints[index % _homeCategoryTints.length];
}

class _HomeCategoryTile extends StatelessWidget {
  const _HomeCategoryTile({required this.achievement, required this.homeState, required this.tint});

  final AchievenmentResponseEntity achievement;
  final HomeState homeState;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final fraction = _fraction();
    final percent = (fraction * 100).round();
    final name = achievement.categoryTitle.text;
    final imageUrl = homeState.categories.where((s) => s.id == achievement.categoryId).firstOrNull?.image ?? '';

    return Semantics(
      button: true,
      label: '$name $percent%',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openInExplore(context),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10.r)),
                alignment: Alignment.center,
                child: CacheNetworkGraphic(url: imageUrl, width: 21.w, height: 21.w, fit: BoxFit.contain),
              ),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _poppins(11.5, FontWeight.w600, height: 1.25),
                    ),
                    6.verticalSpace,
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99.r),
                      child: Container(
                        height: 5.h,
                        color: _homeProgressTrackColor,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: fraction,
                          child: Container(height: 5.h, color: AppCustomColor.brandPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Progress over the category's WHOLE catalog (every course shown in
  /// Explore), each course counting as one unit in [0,1]: a completed course =
  /// 1.0, an in-progress course = its keypoint fraction, an untouched course = 0.
  ///
  /// The achievement API only returns rows for the courses the user has
  /// STARTED (`achievement.totalCourse` counts just those), so dividing by it
  /// made a user who finished the 2 courses they touched read as 100% even
  /// though the category has 9. The denominator must be the catalog size from
  /// HomeCubit; fall back to `achievement.totalCourse` only if the category
  /// isn't loaded yet, so the bar never divides by zero or disappears.
  double _fraction() {
    final catalogCount = homeState.categories.where((s) => s.id == achievement.categoryId).firstOrNull?.courses.length ?? 0;
    final denominator = catalogCount > 0 ? catalogCount : achievement.totalCourse;
    if (denominator <= 0) return 0;

    final completedUnits = achievement.courses.fold<double>(0, (sum, c) {
      if (c.isCompleted) return sum + 1.0;
      if (c.totalKeypoints > 0) return sum + (c.completedKeypoints / c.totalKeypoints).clamp(0.0, 1.0);
      return sum;
    });
    return (completedUnits / denominator).clamp(0.0, 1.0);
  }

  /// Tapping a tile opens that category's full course list.
  ///
  /// It used to drop the reader on the Explore tab scrolled to the category's
  /// own section. Explore no longer has category sections, and a tile that
  /// names ONE topic should not land on a mixed, curated page — so it opens the
  /// list that is actually about that topic. No-op if the category isn't in the
  /// catalog.
  void _openInExplore(BuildContext context) {
    final homeCubit = AppDI.injector.get<HomeCubit>();
    final index = homeCubit.state.categories.indexWhere((s) => s.id == achievement.categoryId);
    if (index < 0) return;
    AppHaptic.select();
    homeCubit.selectCategoryIndex(index);
    AppDI.injector.get<CourseCubit>().setAllCourseSource('home_progress');
    CategoryCoursesRoute(categoryId: achievement.categoryId).push(context);
  }
}
