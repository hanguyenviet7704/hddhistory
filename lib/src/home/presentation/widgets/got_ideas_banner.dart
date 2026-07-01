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
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            // Figma node 10725:31664: #6964DB
            color: const Color(0xFF6964DB),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              // Origami paper-bird mascot (Figma node 10725:31666).
              SvgPicture.asset(
                AppAsset.svg.app.icGotIdeasBird,
                width: 50.8.w,
                height: 35.2.w,
                fit: BoxFit.contain,
              ),
              8.horizontalSpace,
              // Title + subtitle sit inline (Figma node 10725:31678).
              Expanded(
                // The title sizes to its content; the subtitle takes the rest
                // of the row so it shows in full (no "…" truncation).
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText(
                      context.l10n.home.inAppSurveyEntryTitle,
                      style: AppStyle.textBold16.copyWith(
                        color: AppCustomColor.backgroundWhite,
                      ),
                      maxLines: 1,
                    ),
                    4.horizontalSpace,
                    Expanded(
                      child: AppText(
                        context.l10n.home.inAppSurveyEntrySubtitle,
                        style: AppStyle.text12.copyWith(
                          color: AppCustomColor.backgroundWhite.withValues(alpha: 0.70),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              // Chevron affordance (Figma node 10725:31681) — white chevron,
              // 36px tap target, soft drop shadow, no fill.
              SizedBox(
                width: 36.w,
                height: 36.w,
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppCustomColor.backgroundWhite,
                    size: 24.w,
                    shadows: const [
                      Shadow(
                        color: Color(0x14000000),
                        offset: Offset(0, 1),
                        blurRadius: 1.5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
