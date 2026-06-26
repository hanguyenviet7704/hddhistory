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
          prev.courses != curr.courses,
      builder: (context, state) {
        if (!state.isSearchActive) return const SizedBox.shrink();

        final allCourses = state.courses;

        if (state.searchQuery.isEmpty) {
          return _SearchPromptView();
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
