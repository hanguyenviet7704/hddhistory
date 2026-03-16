part of '../../../../lesson.dart';

class CompletionHeaderCard extends StatelessWidget {
  final String title;

  const CompletionHeaderCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAsset.images.app.keypointCompleteDecoration.path,
          width: 227.w,
          height: 95.h,
          fit: BoxFit.contain,
        ),
        16.verticalSpace,
        AppText(
          context.l10n.exercise.exerciseLessonCompleteTitle.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textTertiary,
            fontWeight: FontWeight.w600,
            height: 1.75,
          ),
        ),
        4.verticalSpace,
        AppText(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppStyle.text20.copyWith(
            color: AppCustomColor.textPrimary,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
