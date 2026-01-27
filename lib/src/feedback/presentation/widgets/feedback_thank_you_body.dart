part of '../../feedback.dart';

class FeedbackThankYouBody extends StatelessWidget {
  final String titleLine1;
  final String titleLine2;
  final String subtitle;

  const FeedbackThankYouBody({
    super.key,
    required this.titleLine1,
    required this.titleLine2,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: AppCustomColor.backgroundWhite,
          ),
          child: Container(
            width: 327.w,
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppCustomColor.feedbackThankYouOverlay,
                  AppCustomColor.feedbackThankYouTint,
                ],
                stops: const [0.61, 1],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                12.verticalSpace,
                AppText(
                  titleLine1,
                  textAlign: TextAlign.center,
                  style: AppStyle.text20.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppCustomColor.textPrimary,
                    height: 1.5,
                  ),
                ),
                AppText(
                  titleLine2,
                  textAlign: TextAlign.center,
                  style: AppStyle.text20.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppCustomColor.textPrimary,
                    height: 1.5,
                  ),
                ),
                8.verticalSpace,
                AppText(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.textTertiary,
                    height: 1.75,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -92.h,
          child: AppAsset.images.app.feedbackStarBright.image(
            width: 200.w,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
