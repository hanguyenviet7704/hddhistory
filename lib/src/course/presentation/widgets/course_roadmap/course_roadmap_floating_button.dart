part of '../../../course.dart';

class CourseRoadmapFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const CourseRoadmapFloatingButton({
    super.key,
    required this.onPressed,
    this.label = 'Start lesson',
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      onPressed: onPressed,
      width: 160.w,
      height: 54.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      borderRadius: BorderRadius.circular(1000.r),
      child: AppText(
        label,
        style: AppStyle.textBold16.copyWith(
          color: AppCustomColor.textWhite,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
  }
}
