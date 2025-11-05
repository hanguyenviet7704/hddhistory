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
                        SizedBox(height: 48.h), // Space for close button

                        // Lesson header (title, type, duration)
                        LessonListHeader(lesson: lesson),
                        SizedBox(height: 16.h),

                        // Lesson description
                        LessonDescription(
                          description: lesson.description.text,
                        ),
                        SizedBox(height: 12.h),

                        // Key points section header
                        const KeypointsSectionHeader(),
                        SizedBox(height: 16.h),

                        // Key points list
                        if (lesson.keypoints.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.h),
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
                            separatorBuilder: (context, index) => SizedBox(height: 16.h),
                            itemBuilder: (context, index) {
                              final keypoint = lesson.keypoints[index];

                              // TODO: Replace with actual data from API
                              // For now, using index to demonstrate different states
                              final strengthLevel = index == 0
                                  ? StrengthLevel.weak
                                  : index == 1
                                      ? StrengthLevel.morePractice
                                      : StrengthLevel.optional;
                              final isCompleted = index == 0;

                              return KeypointCard(
                                keypoint: keypoint,
                                isCompleted: isCompleted,
                                strengthLevel: strengthLevel,
                                onTap: () {
                                  // TODO: Navigate to keypoint detail/learning page
                                  // For now, just log the tap
                                  debugPrint('Tapped on keypoint: ${keypoint.title.text}');
                                },
                              );
                            },
                          ),

                        SizedBox(height: 32.h), // Bottom spacing
                      ],
                    ),
                  ),
                );
              },
            ),

            // Close button (top-right)
            Positioned(
              top: 8.h,
              right: 12.w,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      size: 24.sp,
                      color: AppCustomColor.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}