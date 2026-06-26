part of '../../home.dart';

class GotIdeasBanner extends StatelessWidget {
  const GotIdeasBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.home.inAppSurveyEntrySemantics,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppCustomColor.brandPrimary,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppCustomColor.backgroundWhite,
                size: 20.w,
              ),
              12.horizontalSpace,
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${context.l10n.home.inAppSurveyEntryTitle} ',
                        style: AppStyle.textBold14.copyWith(
                          color: AppCustomColor.backgroundWhite,
                        ),
                      ),
                      TextSpan(
                        text: context.l10n.home.inAppSurveyEntrySubtitle,
                        style: AppStyle.text14.copyWith(
                          color: AppCustomColor.backgroundWhite.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              8.horizontalSpace,
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppCustomColor.backgroundWhite,
                size: 16.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
