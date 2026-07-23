part of '../../profile.dart';

/// Full-screen "all achievements" list — one section per skillset with
/// badges, each a 3-column grid. Deliberately NOT a go_router route: it's
/// opened via a plain [Navigator.push] on the root navigator from
/// [_openAchievements] (see profile_page.dart) so it covers the bottom nav
/// without adding a new typed route / rerunning the router codegen. Needs
/// [AchievenmentProgressCubit] provided by its caller via BlocProvider.value.
class AchievementsFullPage extends StatefulWidget {
  const AchievementsFullPage({super.key});

  @override
  State<AchievementsFullPage> createState() => _AchievementsFullPageState();
}

class _AchievementsFullPageState extends State<AchievementsFullPage> {
  @override
  void initState() {
    super.initState();
    // First-frame view hook (spec profile_achieve_scr_view) — this page is
    // pushed on the root navigator, so a fresh instance/initState per open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppService.instance.appTrackingService.trackProfileAchieveScrView();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('achievements-page'),
      backgroundColor: _profileBackground,
      appBar: AppBar(
        backgroundColor: _profileBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: IconButton(
            key: const Key('achievements-back-button'),
            onPressed: () {
              AppHaptic.select();
              AppService.instance.appTrackingService.trackProfileAchieveBackClick();
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppCustomColor.textPrimary, size: 20.w),
          ),
        ),
        title: AppText(
          context.l10n.setting.achievementsTitle,
          style: _poppins(17, FontWeight.w500),
        ),
      ),
      body: BlocBuilder<AchievenmentProgressCubit, AchievenmentProgressState>(
        buildWhen: (previous, current) => previous.status != current.status || previous.achievenments != current.achievenments,
        builder: (context, state) {
          final bool isLoading = state.status == AchievenmentProgressStatus.loading && state.achievenments.isEmpty;
          if (isLoading) return const Center(child: CircularProgressIndicator());

          final bool isFailure = state.status == AchievenmentProgressStatus.failure && state.achievenments.isEmpty;
          if (isFailure) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48.w, color: AppCustomColor.textTertiary),
                    16.verticalSpace,
                    AppText(
                      state.errorMessage ?? '',
                      textAlign: TextAlign.center,
                      style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                    ),
                    16.verticalSpace,
                    OutlinedButton(
                      onPressed: () {
                        AppHaptic.select();
                        context.read<AchievenmentProgressCubit>().loadAllAchievenmentResponses();
                      },
                      child: AppText(
                        context.l10n.monetization.retry,
                        style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final sections = state.achievenments.where((a) => a.totalCourse > 0).toList();
          if (sections.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 48.w, color: AppCustomColor.textTertiary),
                    16.verticalSpace,
                    AppText(
                      context.l10n.setting.settingProfileAchievementsEmptyTitle,
                      textAlign: TextAlign.center,
                      style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
                    ),
                    8.verticalSpace,
                    AppText(
                      context.l10n.setting.settingProfileAchievementsEmptyMessage,
                      textAlign: TextAlign.center,
                      style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: 8.h)),
              for (int i = 0; i < sections.length; i++) ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
                  sliver: SliverToBoxAdapter(child: _AchievementSectionHeader(achievement: sections[i])),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, i == sections.length - 1 ? 0 : 30.h),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 24.h,
                      crossAxisSpacing: 12.w,
                      // Fixed extent: 88×96 badge + up to a 2-line title + a
                      // 7px progress bar. Sized with headroom for a longer
                      // (e.g. Vietnamese) title AND for textScaleFactor up to
                      // ~2.0 (SliverGrid cells can't auto-size to content),
                      // so large-text accessibility settings don't overflow
                      // the cell — at the cost of a little extra whitespace
                      // under short badge titles at the default text scale.
                      mainAxisExtent: 210.h,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _AchievementBadgeGridItem(
                        course: sections[i].courses[index],
                        skillsetId: sections[i].skillsetId,
                        skillsetName: sections[i].skillsetTitle.en.isNotEmpty ? sections[i].skillsetTitle.en : sections[i].skillsetTitle.text,
                      ),
                      childCount: sections[i].courses.length,
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.viewPaddingOf(context).bottom + 24.h)),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementSectionHeader extends StatelessWidget {
  const _AchievementSectionHeader({required this.achievement});

  final AchievenmentResponseEntity achievement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppText(
            achievement.skillsetTitle.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _poppins(20, FontWeight.w700),
          ),
        ),
        8.horizontalSpace,
        AppText(
          context.l10n.setting.settingProfileAchievementsSectionProgress(
            completed: achievement.completedCourse,
            total: achievement.totalCourse,
          ),
          style: AppStyle.textBold14.copyWith(fontSize: 15.sp, color: const Color(0xFF8891A3)),
        ),
      ],
    );
  }
}

class _AchievementBadgeGridItem extends StatelessWidget {
  const _AchievementBadgeGridItem({
    required this.course,
    required this.skillsetId,
    required this.skillsetName,
  });

  final CourseLevelProgressEntity course;
  final String skillsetId;
  final String skillsetName;

  String _resolveCourseName() {
    final String name = course.courseTitle.en.trim();
    if (name.isNotEmpty) return name;
    return course.title;
  }

  // Mirrors UserAchievementCourseItem's onTap exactly (same tracking call +
  // same bottom sheet), just reached from the grid instead of the old
  // profile-page carousel.
  void _onTap(BuildContext context) {
    final trackingData = CourseTrackingData.fromTrackingValues(
      skillsetId: skillsetId,
      skillsetName: skillsetName,
      courseId: course.courseId,
      courseName: _resolveCourseName(),
    );
    AppService.instance.appTrackingService.trackSettingBadgeClick(trackingData);
    context.read<AchievenmentProgressCubit>().loadCourseLevelProgress(course.courseId);
    UserAchievementBottomSheet.show(
      context,
      courseId: course.courseId,
      initialLevel: course.level,
      skillsetId: skillsetId,
      skillsetName: skillsetName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: course.title,
      child: GestureDetector(
        key: ValueKey('achievement-badge-${course.courseId}-${course.level.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          _onTap(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 88.w,
              height: 96.h,
              child: course.badgeUrl.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppCustomColor.borderSecondary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    )
                  : CacheNetworkGraphic(url: course.badgeUrl, width: 88.w, height: 96.h, fit: BoxFit.contain),
            ),
            10.verticalSpace,
            AppText(
              course.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.text13.copyWith(fontWeight: FontWeight.w600, color: AppCustomColor.textPrimary),
            ),
            if (!course.hideProgress) ...[
              10.verticalSpace,
              UserAchievementProgressBar(
                progress: course.progress,
                width: 80.w,
                height: 7.h,
                backgroundColor: _profileProgressTrackColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
