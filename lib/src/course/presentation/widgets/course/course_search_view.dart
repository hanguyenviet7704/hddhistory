part of '../../../course.dart';

/// Overlay that shows search states: recent suggestions, filtered results,
/// or an empty-result message. Rendered by the course page when
/// [CourseCubit.isSearchActive] is true.
class CourseSearchView extends StatelessWidget {
  const CourseSearchView({super.key});

  void _navigateToCourse(BuildContext context, CourseEntity course) {
    context.read<PageCubit>().setCurrentIndex(1);
    context.read<CourseRoadmapCubit>().setRoadmapSource('search');
    context.read<HomeCubit>().selectCourseFromCourseId(course.id);
    CourseRoadmapRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseCubit, CourseState>(
      buildWhen: (prev, curr) =>
          prev.searchQuery != curr.searchQuery ||
          prev.isSearchActive != curr.isSearchActive ||
          prev.courses != curr.courses ||
          prev.searchHistory != curr.searchHistory ||
          prev.isLoadingHistory != curr.isLoadingHistory,
      builder: (context, state) {
        if (!state.isSearchActive) return const SizedBox.shrink();

        final allCourses = state.courses;

        if (state.searchQuery.isEmpty) {
          if (state.isLoadingHistory) {
            return const _HistoryLoadingView();
          }
          if (state.searchHistory.isEmpty) {
            return const _SearchPromptView();
          }
          return _RecentSection(
            history: state.searchHistory,
            onTap: (query) => context.read<CourseCubit>().updateSearch(query),
            onClearAll: () => context.read<CourseCubit>().clearSearchHistory(),
          );
        }

        final query = state.searchQuery.toLowerCase();
        final results = allCourses
            .where((c) => c.title.text.toLowerCase().contains(query))
            .toList();

        if (results.isEmpty) {
          return _NoResultView(query: state.searchQuery);
        }

        return _SearchResultList(
          courses: results,
          onCourseTap: (course) => _navigateToCourse(context, course),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
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

class _RecentSection extends StatelessWidget {
  const _RecentSection({
    required this.history,
    required this.onTap,
    required this.onClearAll,
  });

  final List<String> history;
  final ValueChanged<String> onTap;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                context.l10n.allcourse.searchRecent,
                style: AppStyle.textBold14.copyWith(
                  color: AppCustomColor.textPrimary,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: context.l10n.allcourse.searchClearAll,
                child: TextButton(
                  key: const Key('search-history-clear-all-button'),
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    minimumSize: Size(48.w, 36.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: AppText(
                    context.l10n.allcourse.searchClearAll,
                    style: AppStyle.text14.copyWith(
                      color: AppCustomColor.brandPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          8.verticalSpace,
          ListView.separated(
            key: const Key('search-history-list'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: AppCustomColor.borderDefault,
            ),
            itemBuilder: (context, index) {
              final query = history[index];
              return Semantics(
                button: true,
                label: query,
                child: InkWell(
                  key: ValueKey('search-history-item-$index'),
                  onTap: () => onTap(query),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16.w,
                          color: AppCustomColor.textTertiary,
                        ),
                        10.horizontalSpace,
                        Expanded(
                          child: AppText(
                            query,
                            style: AppStyle.text14.copyWith(
                              color: AppCustomColor.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        8.horizontalSpace,
                        Icon(
                          Icons.north_west_rounded,
                          size: 14.w,
                          color: AppCustomColor.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: courses.length,
      separatorBuilder: (_, _) => 8.verticalSpace,
      itemBuilder: (context, index) => CourseListTile(
        course: courses[index],
        onTap: () => onCourseTap(courses[index]),
      ),
    );
  }
}

class _NoResultView extends StatelessWidget {
  const _NoResultView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56.w,
              color: AppCustomColor.textTertiary,
            ),
            16.verticalSpace,
            AppText(
              context.l10n.allcourse.searchNoResults(query: query),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.textBold16
                  .copyWith(color: AppCustomColor.textPrimary),
            ),
            8.verticalSpace,
            AppText(
              context.l10n.allcourse.searchNoResultsHint,
              textAlign: TextAlign.center,
              style: AppStyle.text14
                  .copyWith(color: AppCustomColor.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
