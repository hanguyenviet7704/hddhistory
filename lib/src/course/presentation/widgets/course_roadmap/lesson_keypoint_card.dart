part of '../../../course.dart';

class LessonKeypointCard extends StatelessWidget {
  final LessonEntity lesson;
  final VoidCallback? onTap;

  const LessonKeypointCard({
    super.key,
    required this.lesson,
    this.onTap,
  });

  KeypointEntity get keypoint => lesson.firstKeypoint;

  Color get _textColor {
    switch (keypoint.progess) {
      case ProcessEnum.done:
        return AppCustomColor.textPrimary;
      case ProcessEnum.inProgress:
        return AppCustomColor.brandPrimary300;
      case ProcessEnum.notStarted:
        return AppCustomColor.textSecondary;
    }
  }

  Color get _borderColor {
    return AppCustomColor.borderDefault;
  }

  double get _borderWidth {
    return 1.w;
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = context.select<CourseRoadmapCubit, bool>((cubit) => cubit.state.isLessonSelected(lesson));
    final borderColor = isSelected ? AppCustomColor.brandPrimary : _borderColor;
    final borderWidth = isSelected ? 2.w : _borderWidth;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            constraints: BoxConstraints(minHeight: 44.h, minWidth: double.infinity),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppCustomColor.borderDefault,
                  blurRadius: 4,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: AppText(
              keypoint.title.text,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w500,
                color: _textColor,
                height: 1.75,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
