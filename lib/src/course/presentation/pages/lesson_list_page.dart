part of '../../course.dart';

class LessonListPage extends StatelessWidget {
  const LessonListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            BlocBuilder<CourseLessonCubit, CourseLessonState>(
              builder: (context, state) {
                if (state.status == CourseLessonStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.status == CourseLessonStatus.failure) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.sp,
                            color: AppCustomColor.errorRed,
                          ),
                          SizedBox(height: 16.h),
                          AppText(
                            'An error occurred',
                            style: AppStyle.text16.copyWith(
                              color: AppCustomColor.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final lesson = state.selectedLesson;

                // Check if lesson data is empty (id is empty means no data loaded)
                if (lesson.id.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: AppText(
                        'No lesson data available',
                        style: AppStyle.text16.copyWith(
                          color: AppCustomColor.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lesson header (title, type, duration)
                        LessonListHeader(lesson: lesson),
                        16.verticalSpace,
                        // Lesson description
                        AppText(
                          lesson.description.text,
                          style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                        ),
                        12.verticalSpace,

                        // Key points section header
                        const KeypointsSectionHeader(),
                        16.verticalSpace,

                        // Key points list
                        if (lesson.keypoints.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.w),
                            child: Center(
                              child: AppText(
                                'No key points available',
                                style: AppStyle.text14.copyWith(
                                  color: AppCustomColor.textTertiary,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lesson.keypoints.length,
                            separatorBuilder: (context, index) => 16.verticalSpace,
                            itemBuilder: (context, index) {
                              final keypoint = lesson.keypoints[index];

                              return KeypointCard(
                                keypoint: keypoint,
                                onTap: () {
                                  // TODO: Navigate to keypoint detail/learning page
                                  // For now, just log the tap
                                  debugPrint('Tapped on keypoint: ${keypoint.title.text}');
                                },
                              );
                            },
                          ),

                        32.verticalSpace,
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
