part of '../../course.dart';

class SkillsetCoursesPage extends StatelessWidget {
  const SkillsetCoursesPage({
    super.key,
    required this.skillsetId,
  });

  final String skillsetId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) => prev.skillsets != curr.skillsets,
      builder: (context, homeState) {
        final skillset = homeState.skillsets.firstWhere(
          (s) => s.id == skillsetId,
          orElse: () => const SkillsetEntity(),
        );

        // Progress (numberOfLessonPassed) lives in ProgressCubit.myCourses, not
        // in the skillset list — merge it in by course id.
        final progressById =
            progressLookup(context.watch<ProgressCubit>().state);
        final sorted = sortCoursesForExplore(skillset.courses, progressById);

        return Scaffold(
          key: const Key('skillset-courses-page'),
          backgroundColor: AppCustomColor.backgroundWhite,
          appBar: AppBar(
            backgroundColor: AppCustomColor.backgroundWhite,
            elevation: 0,
            centerTitle: true,
            leading: Semantics(
              button: true,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              child: IconButton(
                onPressed: () => context.back(),
                constraints: BoxConstraints(minWidth: 48.w, minHeight: 48.w),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppCustomColor.textPrimary,
                  size: 20.w,
                ),
              ),
            ),
            title: AppText(
              skillset.title.text,
              style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
            ),
          ),
          body: sorted.isEmpty
              ? const CourseEmptyState()
              : GridView.builder(
                  key: const Key('skillset-courses-grid'),
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 24.h,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final course = sorted[index];
                    final progressInfo = _progressInfoFor(course, progressById);
                    return _CourseGridCard(
                      key: ValueKey(course.id),
                      course: course,
                      completedLessons: progressInfo.completedLessons,
                      totalLessons: progressInfo.totalLessons,
                      onTap: () => _handleCourseTap(context, skillset, course),
                    );
                  },
                ),
        );
      },
    );
  }

  _CourseProgressInfo _progressInfoFor(
    CourseEntity course,
    Map<String, CourseEntity> progressById,
  ) {
    final p = resolveCourseProgress(course, progressById);
    if (p.passed <= 0) return const _CourseProgressInfo();
    return _CourseProgressInfo(
      showProgress: true,
      completedLessons: p.passed,
      totalLessons: p.total,
    );
  }

  void _handleCourseTap(BuildContext context, SkillsetEntity skillset, CourseEntity course) {
    if (course.status == CoursePublishStatus.comingSoon) {
      _showComingSoonSheet(context, course);
      return;
    }
    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }
    context.read<CourseRoadmapCubit>().setRoadmapSource('skillset_courses');
    context.read<HomeCubit>()
      ..selectSkillset(skillset)
      ..selectCourse(course);
    CourseRoadmapRoute().go(context);
    context.read<PageCubit>().setCurrentIndex(1);
  }
}

