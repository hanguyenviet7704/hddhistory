part of '../../course.dart';

class CourseRoadmapPage extends StatelessWidget {
  const CourseRoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get data from HomeCubit for the course header
    final homeState = context.watch<HomeCubit>().state;
    final currentCourse = homeState.currentCourse;

    // Get the first course from current skillset for header display
    final currentSkillset = homeState.currentSkillset;
    final firstCourse = currentSkillset.courses.isNotEmpty
        ? currentSkillset.courses.first
        : CourseEntity();

    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: SafeArea(
        child: BlocBuilder<CourseCubit, CourseState>(
          builder: (context, courseState) {
            return Column(
              children: [
                // Top progress bar
                TopProgressBar(
                  courseName: currentSkillset.title.text.isNotEmpty
                      ? currentSkillset.title.text
                      : 'Course Roadmap',
                ),
                // Main content
                Expanded(
                  child: _buildContent(
                    context,
                    courseState,
                    firstCourse,
                    currentCourse,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CourseState courseState,
    CourseEntity course,
    UserProgressEntity progress,
  ) {
    // Handle loading state
    if (courseState.status == CourseStatus.loading && courseState.roadmap.id.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: AppCustomColor.brandPrimary,
        ),
      );
    }

    // Handle error state
    if (courseState.status == CourseStatus.failure) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64.w,
                color: AppCustomColor.textQuaternary,
              ),
              16.verticalSpace,
              AppText(
                courseState.errorMessage ?? 'Failed to load roadmap',
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
              16.verticalSpace,
              GestureDetector(
                onTap: () {
                  final courseId = progress.courseId.isNotEmpty
                      ? progress.courseId
                      : course.id;
                  if (courseId.isNotEmpty) {
                    context.read<CourseCubit>().loadRoadmap(courseId);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppCustomColor.brandPrimary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: AppText(
                    'Retry',
                    style: AppStyle.text14.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppCustomColor.textWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Handle empty state
    if (courseState.roadmap.node.isEmpty) {
      return Center(
        child: AppText(
          'No roadmap available',
          style: AppStyle.text14.copyWith(
            color: AppCustomColor.textSecondary,
          ),
        ),
      );
    }

    // Calculate completed lessons
    final completedLessons = progress.lessonsResult.where((r) => r.passed).length;
    final totalLessons = courseState.roadmap.lessonList.length;

    // Main content with roadmap
    return RefreshIndicator(
      onRefresh: () async {
        final courseId = progress.courseId.isNotEmpty
            ? progress.courseId
            : course.id;
        if (courseId.isNotEmpty) {
          context.read<CourseCubit>().loadRoadmap(courseId);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20.h,
          children: [
            // Course header card
            CourseHeaderCard(
              course: course,
              completedLessons: completedLessons,
              totalLessons: totalLessons,
            ),
            // Roadmap timeline list
            RoadmapTimelineList(
              nodes: courseState.roadmap.node,
              onLessonTap: () {
                // TODO: Navigate to lesson detail page
                // This will be implemented when lesson detail page is ready
              },
            ),
          ],
        ),
      ),
    );
  }
}