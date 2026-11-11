part of '../../course.dart';

/// The full list behind a collection's chevron on the Explore tab.
///
/// Reads the collection out of [ExploreCubit] rather than fetching it: the tab
/// that opened this page already holds every course in the strip (a collection
/// is capped at eight), so a request here would ask the server for bytes the
/// app is already sitting on.
class CollectionCoursesPage extends StatelessWidget {
  const CollectionCoursesPage({super.key, required this.collectionId});

  final String collectionId;

  @override
  Widget build(BuildContext context) {
    final section = context.select<ExploreCubit, ExploreSectionEntity?>(
      (cubit) => cubit.state.sections
          .where((s) => s.type == ExploreSectionType.curated && s.id == collectionId)
          .firstOrNull,
    );

    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CollectionCoursesHeader(title: section?.title.text ?? ''),
            Expanded(
              child: section == null
                  // Reachable by a cold deep link, or after the tab reloaded
                  // and the collection was unpublished meanwhile.
                  ? const CourseEmptyState()
                  : _CollectionCoursesGrid(section: section),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionCoursesHeader extends StatelessWidget {
  const _CollectionCoursesHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 20.w, 12.h),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: context.l10n.common.back,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AppHaptic.select();
                context.pop();
              },
              child: SizedBox(
                width: 44.w,
                height: 44.w,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 28.w,
                  color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                ),
              ),
            ),
          ),
          Expanded(
            child: AppText(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFont.mulish,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionCoursesGrid extends StatelessWidget {
  const _CollectionCoursesGrid({required this.section});

  final ExploreSectionEntity section;

  @override
  Widget build(BuildContext context) {
    final progressById = progressLookup(context.watch<ProgressCubit>().state);
    final courses = section.courses;

    if (courses.isEmpty) return const CourseEmptyState();

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - 40.w;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 80.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: _kCourseGridColGap,
            mainAxisSpacing: _kCourseGridRowGap,
            // Measured, not a ratio: the cover is square so a cell's height
            // depends on the column width — see [courseGridCellExtent].
            mainAxisExtent: courseGridCellExtent(gridWidth),
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final enrolled = progressById.containsKey(course.id);
            final progress = resolveCourseProgress(course, progressById);
            return _CourseGridCard(
              key: ValueKey(course.id),
              course: course,
              completedLessons: enrolled ? progress.passed : null,
              totalLessons: enrolled ? progress.total : null,
              onTap: () => _openCourse(context, course, section),
            );
          },
        );
      },
    );
  }

  void _openCourse(BuildContext context, CourseEntity course, ExploreSectionEntity section) {
    if (course.isComingSoonNow) {
      _showComingSoonSheet(context, course);
      return;
    }
    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }

    ExploreTracking.track(
      TrackingKey.exploreCourseClick,
      parameters: {
        ...ExploreTracking.sectionParams(section),
        ...ExploreTracking.courseParams(course),
        'source': 'collection_list',
      },
    );

    final homeCubit = context.read<HomeCubit>();
    for (final category in homeCubit.state.categories) {
      final index = category.courses.indexWhere((c) => c.id == course.id);
      if (index >= 0) {
        homeCubit
          ..selectCategory(category)
          ..selectCourseIndex(index);
        break;
      }
    }
    context.read<CourseRoadmapCubit>().setRoadmapSource(kRoadmapSourceCollectionList);
    CourseRoadmapRoute().go(context);
    context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
  }
}
