part of '../../../course.dart';

/// Overlay that shows search states: recent suggestions, filtered results,
/// or an empty-result message. Rendered by the course page when
/// [CourseCubit.isSearchActive] is true.
class CourseSearchView extends StatelessWidget {
  const CourseSearchView({super.key});

  void _navigateToCourse(BuildContext context, CourseEntity course, {required String source}) {
    if (course.isComingSoonNow) {
      _showComingSoonSheet(context, course);
      return;
    }
    // No skillset is in scope on the search/recent surfaces, so skill_id /
    // skill_name are intentionally omitted here (spec).
    ExploreTracking.track(
      TrackingKey.exploreCourseClick,
      parameters: {
        ...ExploreTracking.courseParams(course),
        'course_state': ExploreTracking.courseState(course),
        'source': source,
      },
    );
    context.read<CourseRoadmapCubit>().setRoadmapSource('search');
    context.read<HomeCubit>().selectCourseFromCourseId(course.id);
    CourseRoadmapRoute().go(context);
    // Set the route name explicitly (not just the index): .go() to the roadmap
    // branch root doesn't re-fire the observer, so otherwise currentRouteName
    // stays non-primary and the bottom nav (the only exit) stays hidden.
    context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseCubit, CourseState>(
      buildWhen: (prev, curr) =>
          prev.searchQuery != curr.searchQuery ||
          prev.isSearchActive != curr.isSearchActive ||
          prev.status != curr.status ||
          prev.courses != curr.courses ||
          prev.recentCourses != curr.recentCourses ||
          prev.isLoadingRecent != curr.isLoadingRecent,
      builder: (context, state) {
        if (!state.isSearchActive) return const SizedBox.shrink();

        // Empty query → "Recent" (recently-viewed courses).
        if (state.searchQuery.trim().isEmpty) {
          if (state.isLoadingRecent) {
            return const _HistoryLoadingView();
          }
          if (state.recentCourses.isEmpty) {
            return const _SearchPromptView();
          }
          return _RecentSection(
            courses: state.recentCourses,
            onTapCourse: (course) => _navigateToCourse(context, course, source: 'recent'),
            onClearAll: () => context.read<CourseCubit>().clearRecentCourses(),
          );
        }

        // Results come from the server-side search API (CourseCubit._runSearch,
        // GET /courses?search=). Coming-soon courses are already filtered out.
        if (state.status == CourseStatus.loading) {
          return const _HistoryLoadingView();
        }

        final results = state.courses;
        if (results.isEmpty) {
          return _NoResultView(query: state.searchQuery);
        }

        return _SearchResultList(
          courses: results,
          onCourseTap: (course) => _navigateToCourse(context, course, source: 'search'),
        );
      },
    );
  }
}

class _HistoryLoadingView extends StatelessWidget {
  const _HistoryLoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 16.h,
            width: 80.w,
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundGray,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          12.verticalSpace,
          ...List.generate(
            4,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                height: 20.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundGray,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Recent" section — recently-viewed courses rendered as Card3X1 tiles
/// (Figma node 10736-50550). Tapping a card opens that course.
class _RecentSection extends StatelessWidget {
  const _RecentSection({
    required this.courses,
    required this.onTapCourse,
    required this.onClearAll,
  });

  final List<CourseEntity> courses;
  final ValueChanged<CourseEntity> onTapCourse;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Generous bottom padding so the last card scrolls clear of the
      // floating bottom nav bar.
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 120.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                context.l10n.allcourse.searchRecent,
                style: AppStyle.textBold16.copyWith(
                  color: AppCustomColor.textPrimary,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: context.l10n.allcourse.searchClearAll,
                child: TextButton(
                  key: const Key('recent-courses-clear-all-button'),
                  onPressed: () {
                    AppHaptic.select();
                    ExploreTracking.track(TrackingKey.exploreRecentClearClick);
                    onClearAll();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    minimumSize: Size(48.w, 36.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: AppText(
                    context.l10n.allcourse.searchClearAll,
                    style: AppStyle.textBold14.copyWith(
                      color: AppCustomColor.brandPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          ListView.separated(
            key: const Key('recent-courses-list'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            separatorBuilder: (_, _) => 12.verticalSpace,
            itemBuilder: (context, index) => _SearchCourseCard(
              key: ValueKey('recent-course-${courses[index].id}'),
              course: courses[index],
              onTap: () => onTapCourse(courses[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPromptView extends StatelessWidget {
  const _SearchPromptView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 48.w,
              color: AppCustomColor.textTertiary,
            ),
            16.verticalSpace,
            AppText(
              context.l10n.allcourse.searchTypeToSearch,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultList extends StatelessWidget {
  const _SearchResultList({
    required this.courses,
    required this.onCourseTap,
  });

  final List<CourseEntity> courses;
  final ValueChanged<CourseEntity> onCourseTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      // Clear the floating bottom nav bar.
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 120.h),
      itemCount: courses.length,
      separatorBuilder: (_, _) => 12.verticalSpace,
      itemBuilder: (context, index) => _SearchCourseCard(
        course: courses[index],
        onTap: () => onCourseTap(courses[index]),
      ),
    );
  }
}

/// Card3X1 style — used in both search results and (future) recent courses.
class _SearchCourseCard extends StatelessWidget {
  const _SearchCourseCard({super.key, required this.course, this.onTap});

  final CourseEntity course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: course.title.text,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                AppHaptic.select();
                onTap!();
              },
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            border: Border.all(color: AppCustomColor.neutral300, width: 1),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: const [
              BoxShadow(color: Color(0xFFEBF0F7), blurRadius: 4),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: CacheNetworkGraphic(
                  url: course.image,
                  width: 100.w,
                  height: 100.w,
                  fit: BoxFit.cover,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      course.title.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.textBold14.copyWith(
                        color: AppCustomColor.textSecondary,
                        height: 1.75,
                      ),
                    ),
                    8.verticalSpace,
                    _CourseProgressChip(course: course),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResultView extends StatelessWidget {
  const _NoResultView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final fullText = context.l10n.allcourse.searchNoResults(query: query);
    final queryMarker = '"$query"';
    final markerIdx = fullText.lastIndexOf(queryMarker);
    final prefix = markerIdx >= 0 ? fullText.substring(0, markerIdx) : fullText;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAsset.images.common.searchNoResult.path,
              width: 120.w,
              height: 120.w,
            ),
            10.verticalSpace,
            RichText(
              textAlign: TextAlign.center,
              // Heading/H4/SemiB — Mulish SemiBold 16/1.5 (Figma 10736:51046).
              // Whole line is SemiBold; only the color differs between the
              // prefix (text/secondary @50%) and the query (text/secondary @80%).
              text: TextSpan(
                style: AppStyle.text16.copyWith(
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: prefix,
                    style: TextStyle(
                      color: AppCustomColor.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                  if (markerIdx >= 0)
                    TextSpan(
                      text: queryMarker,
                      style: TextStyle(
                        color: AppCustomColor.textSecondary.withValues(alpha: 0.8),
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
