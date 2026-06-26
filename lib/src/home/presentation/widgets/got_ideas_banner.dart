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
            // Figma node 10725:31646: #6964DB
            color: const Color(0xFF6964DB),
            borderRadius: BorderRadius.circular(16.r),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      context.l10n.home.inAppSurveyEntryTitle,
                      style: AppStyle.textBold16.copyWith(
                        color: AppCustomColor.backgroundWhite,
                      ),
                    ),
                    2.verticalSpace,
                    AppText(
                      context.l10n.home.inAppSurveyEntrySubtitle,
                      style: AppStyle.text12.copyWith(
                        color: AppCustomColor.backgroundWhite.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppCustomColor.backgroundWhite,
                  size: 18.w,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
