part of '../../../course.dart';

/// Maximum number of courses shown per skillset section in the Explore view.
/// A "View more" button is shown when a skillset has more courses than this.
const int _kMaxCoursesPerSection = 5;

/// Sorts [courses] for display in the Explore screen.
///
/// Order: New (not coming-soon) → In Progress → Not Started → Coming Soon.
List<CourseEntity> sortCoursesForExplore(
  List<CourseEntity> courses,
  List<UserProgressEntity> userProgresses,
) {
  int priority(CourseEntity c) {
    if (c.isNew && c.status != CoursePublishStatus.comingSoon) return 0;
    final progress = userProgresses.firstWhereOrNull((p) => p.courseId == c.id);
    final completed = progress?.lessonsResult.where((r) => r.passed).length ?? 0;
    if (completed > 0 && completed < c.numberOfLesson) return 1; // In Progress
    if (c.status == CoursePublishStatus.comingSoon) return 3; // Coming Soon last
    return 2; // Not Started
  }

  return [...courses]..sort((a, b) => priority(a).compareTo(priority(b)));
}

class AllCourseTab extends StatefulWidget {
  const AllCourseTab({super.key});

  @override
  State<AllCourseTab> createState() => _AllCourseTabState();
}

class _AllCourseTabState extends State<AllCourseTab> with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackAllCourseScrView());
  }

  void _trackAllCourseScrView() {
    if (!mounted) return;
    final source = context.read<CourseCubit>().state.allCourseSource;
    AppService.instance.appTrackingService.trackCourseSelectAllCourseView(source: source);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) => prev.skillsets != curr.skillsets || prev.selectedCourseIndex != curr.selectedCourseIndex,
      builder: (context, homeState) {
        final skillsets = homeState.skillsets;
        if (skillsets.isEmpty) {
          return const CourseEmptyState();
        }
        final progressState = context.watch<ProgressCubit>().state;
        final selectedCategoryIndex = context.watch<CourseCubit>().state.selectedCategoryIndex;

        // Filter skillsets based on selected category. -1 means show all.
        final visibleSkillsets = selectedCategoryIndex < 0
            ? skillsets
            : skillsets.length > selectedCategoryIndex
                ? [skillsets[selectedCategoryIndex]]
                : <SkillsetEntity>[];

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
          itemCount: visibleSkillsets.length,
          itemBuilder: (context, index) {
            final skillset = visibleSkillsets[index];
            return _CourseSection(
              skillset: skillset,
              progressState: progressState,
              isSelected: (courseId) => homeState.isSelectedCourse(courseId),
              onTapCourse: (course, courseIndex) =>
                  _onTapCourse(context, skillset, course, courseIndex),
              showBottomSpacing: index < visibleSkillsets.length - 1,
            );
          },
        );
      },
    );
  }

  void _onTapCourse(
    BuildContext context,
    SkillsetEntity skillset,
    CourseEntity course,
    int index,
  ) {
    // Coming-soon courses show an informational bottom sheet instead of navigating.
    if (course.status == CoursePublishStatus.comingSoon) {
      _showComingSoonSheet(context, course);
      return;
    }

    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }

    AppService.instance.appTrackingService.trackCourseSelectCourseClick(
      skillset,
      course,
      source: 'all_course',
    );

    final isFirstTimeUserChooseCourse = context.read<UserCubit>().state.isFirstTimeUserChooseCourse;
    if (isFirstTimeUserChooseCourse && kDebugMode) {
      AppService.instance.appTrackingService.trackCourseSelectFirstCourseClick(skillset, course);
      CourseIntroPopup.show(
        context,
        course: course,
        onClose: () => _handleCourseTap(context, skillset, course, index),
      );
      return;
    }

    _handleCourseTap(context, skillset, course, index);
  }

  void _handleCourseTap(
    BuildContext context,
    SkillsetEntity skillset,
    CourseEntity course,
    int index,
  ) {
    context.read<CourseRoadmapCubit>().setRoadmapSource('course_selection');
    context.read<HomeCubit>()
      ..selectSkillset(skillset)
      ..selectCourseIndex(index);
    CourseRoadmapRoute().go(context);
    context.read<PageCubit>().setCurrentIndex(1);
  }

  @override
  bool get wantKeepAlive => true;
}

void _showComingSoonSheet(BuildContext context, CourseEntity course) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppCustomColor.backgroundWhite,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              course.title.text,
              style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
              textAlign: TextAlign.center,
            ),
            16.verticalSpace,
            AppText(
              l10n.allcourse.comingSoonDescription,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
              textAlign: TextAlign.center,
            ),
            24.verticalSpace,
            AppButton.primary(
              fullWidthBtn: true,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: AppText(
                l10n.allcourse.comingSoonGotIt,
                style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CourseSection extends StatelessWidget {
  final SkillsetEntity skillset;
  final ProgressState progressState;
  final bool Function(String courseId) isSelected;
  final void Function(CourseEntity course, int courseIndex) onTapCourse;
  final bool showBottomSpacing;

  const _CourseSection({
    required this.skillset,
    required this.progressState,
    required this.isSelected,
    required this.onTapCourse,
    required this.showBottomSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = sortCoursesForExplore(skillset.courses, progressState.userProgresses);
    final displayed = sorted.take(_kMaxCoursesPerSection).toList();
    final hasMore = sorted.length > _kMaxCoursesPerSection;

    // Build the grid children: course cards + optional view-more slot.
    final gridChildren = <Widget>[
      ...displayed.map((course) {
        final originalIndex = skillset.courses.indexWhere((c) => c.id == course.id);
        final progressInfo = _progressInfoFor(progressState, course);
        return _CourseGridCard(
          key: ValueKey(course.id),
          course: course,
          completedLessons: progressInfo.completedLessons,
          totalLessons: progressInfo.totalLessons,
          isSelected: isSelected(course.id),
          onTap: () => onTapCourse(course, originalIndex >= 0 ? originalIndex : displayed.indexOf(course)),
        );
      }),
      if (hasMore) _ViewMoreGridCard(skillset: skillset),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          skillset.title.text,
          style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
        ),
        12.verticalSpace,
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.65,
          children: gridChildren,
        ),
        if (showBottomSpacing) 24.verticalSpace,
      ],
    );
  }

  _CourseProgressInfo _progressInfoFor(ProgressState progressState, CourseEntity course) {
    final userProgress = progressState.userProgresses.firstWhereOrNull(
      (progress) => progress.courseId == course.id,
    );

    if (userProgress == null || userProgress.lessonsResult.isEmpty) {
      return const _CourseProgressInfo();
    }

    final completedLessons = userProgress.lessonsResult.where((result) => result.passed).length;
    if (completedLessons == 0) {
      return const _CourseProgressInfo();
    }

    return _CourseProgressInfo(
      showProgress: true,
      completedLessons: completedLessons,
      totalLessons: course.numberOfLesson,
    );
  }
}

/// Grid-slot card for "View more" — occupies one cell in the 2-column grid,
/// matching the dimensions of [_CourseGridCard].
class _ViewMoreGridCard extends StatelessWidget {
  const _ViewMoreGridCard({required this.skillset});

  final SkillsetEntity skillset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${context.l10n.allcourse.viewMore} ${skillset.title.text}',
      child: GestureDetector(
        onTap: () => SkillsetCoursesRoute(skillsetId: skillset.id).push(context),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppCustomColor.borderDefault, width: 1.5),
            borderRadius: BorderRadius.circular(16.r),
            color: AppCustomColor.backgroundGray,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 28.w,
                color: AppCustomColor.textSecondary,
              ),
              8.verticalSpace,
              AppText(
                context.l10n.allcourse.viewMore,
                style: AppStyle.textBold14.copyWith(
                  color: AppCustomColor.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              4.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: AppText(
                  skillset.title.text,
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical grid card shared between [AllCourseTab] and [SkillsetCoursesPage].
/// Displays thumbnail (portrait-dominant), badge overlay, title, and progress chip.
class _CourseGridCard extends StatelessWidget {
  const _CourseGridCard({
    super.key,
    required this.course,
    this.completedLessons,
    this.totalLessons,
    this.isSelected = false,
    required this.onTap,
  });

  final CourseEntity course;
  final int? completedLessons;
  final int? totalLessons;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: course.title.text,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? AppCustomColor.brandPrimary
                  : AppCustomColor.borderDefault,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16.r),
            color: AppCustomColor.backgroundWhite,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with badge overlay — fills top ~65% of the card.
              Expanded(
                flex: 65,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CacheNetworkGraphic(
                        url: course.image,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 6.h,
                        left: 6.w,
                        child: _CourseBadge(
                          course: course,
                          completedLessons: completedLessons,
                          totalLessons: totalLessons,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Title + progress chip — bottom ~35% of the card.
              Expanded(
                flex: 35,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppText(
                          course.title.text,
                          style: AppStyle.textBold14.copyWith(
                            color: AppCustomColor.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      4.verticalSpace,
                      _CourseProgressChip(course: course),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseProgressInfo {
  final bool showProgress;
  final int? completedLessons;
  final int? totalLessons;

  const _CourseProgressInfo({
    this.showProgress = false,
    this.completedLessons,
    this.totalLessons,
  });
}
