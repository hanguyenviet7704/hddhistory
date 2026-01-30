part of '../../../course.dart';

class CourseRoadmapFloatingButton extends StatelessWidget {
  final String label;

  const CourseRoadmapFloatingButton({
    super.key,
    this.label = 'Start lesson',
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      onPressed: () {
        CourseRoadmapRoute().go(context);
      },
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
