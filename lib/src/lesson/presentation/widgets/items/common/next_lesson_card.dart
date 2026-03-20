part of '../../../../lesson.dart';

class NextLessonCard extends StatelessWidget {
  final String title;

  const NextLessonCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 0,
          child: Container(
            height: 12.h,
            width: 303.w,
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              border: Border.all(
                color: AppCustomColor.borderSecondary,
                width: 2.w,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4.r),
                topRight: Radius.circular(4.r),
                bottomLeft: Radius.circular(8.r),
                bottomRight: Radius.circular(8.r),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            border: Border.all(
              color: AppCustomColor.borderSecondary,
              width: 2.w,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                context.l10n.exercise.exerciseNextLessonLabel.toUpperCase(),
                style: AppStyle.text12.copyWith(
                  color: AppCustomColor.textQuaternary,
                  fontWeight: FontWeight.w700,
                  height: 1.75,
                ),
              ),
              4.verticalSpace,
              AppText(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.text16.copyWith(
                  color: AppCustomColor.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
