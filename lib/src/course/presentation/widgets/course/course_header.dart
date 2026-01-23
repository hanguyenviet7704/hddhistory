part of '../../../course.dart';

class CourseHeader extends StatelessWidget {
  const CourseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: SizedBox(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
                selector: (state) => state.roadmap.id.isNotEmpty,
                builder: (context, isInitialized) {
                  if (!isInitialized) return const SizedBox.shrink();
                  if (!context.canPop()) return const SizedBox.shrink();

                  return GestureDetector(
                    onTap: () {
                      AppService.instance.appTrackingService.trackCourseSelectExit();
                      context.back();
                    },
                    child: Icon(
                      Icons.close,
                      size: 24.w,
                      color: AppCustomColor.textTertiary,
                    ),
                  );
                },
              ),
            ),
            const CourseSegmentedControl(),
          ],
        ),
      ),
    );
  }
}
