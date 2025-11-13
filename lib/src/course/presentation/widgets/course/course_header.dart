part of '../../../course.dart';

class CourseHeader extends StatelessWidget {
  const CourseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            context.text.allcourseExploreSkillsets,
            style: AppStyle.textBold20.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
            selector: (state) => state.roadmap.id.isNotEmpty,
            builder: (context, isInitialized) {
              if (!isInitialized) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => context.back(),
                child: Icon(
                  Icons.close,
                  size: 24.w,
                  color: AppCustomColor.textTertiary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
