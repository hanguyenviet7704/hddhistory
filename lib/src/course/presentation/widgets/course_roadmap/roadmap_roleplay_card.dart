part of '../../../course.dart';

class RoadmapRoleplayCard extends StatelessWidget {
  final LessonEntity lesson;
  final bool isLocked;
  final VoidCallback? onTap;

  const RoadmapRoleplayCard({
    super.key,
    required this.lesson,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = context.select<CourseRoadmapCubit, bool>((cubit) => cubit.state.isLessonSelected(lesson));
    final borderColor = isSelected
        ? AppCustomColor.brandPrimary
        : switch (lesson.roadmapProgress) {
            ProcessEnum.done || ProcessEnum.inProgress => AppCustomColor.brandPrimary,
            ProcessEnum.notStarted => AppCustomColor.borderDefault,
          };
    final borderWidth = isSelected
        ? 3.w
        : switch (lesson.roadmapProgress) {
            ProcessEnum.done || ProcessEnum.inProgress => 3.w,
            ProcessEnum.notStarted => 2.w,
          };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: AppCustomColor.borderDefault,
              blurRadius: 4,
              offset: Offset.zero,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DCachedImage(
              url: lesson.image,
              width: double.infinity,
              height: 120.h,
              fit: BoxFit.cover,
              margin: EdgeInsets.zero,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13.r)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 14.h),
              child: AppText(
                lesson.title.text,
                style: AppStyle.textBold14.copyWith(
                  color: AppCustomColor.brandPrimary,
                  height: 1.75,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
