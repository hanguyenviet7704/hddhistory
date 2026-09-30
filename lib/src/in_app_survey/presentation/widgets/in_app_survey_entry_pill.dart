part of '../../in_app_survey.dart';

class InAppSurveyEntryPill extends StatelessWidget {
  const InAppSurveyEntryPill({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.home.inAppSurveyEntrySemantics,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999.r),
          onTap: () {
            AppHaptic.select();
            onTap();
          },
          child: Container(
            width: min(315.w, MediaQuery.sizeOf(context).width - 40.w),
            padding: EdgeInsets.only(left: 8.w, right: 16.w, top: 6.h, bottom: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(color: _InAppSurveyColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2ECBD5DF),
                  blurRadius: 17,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFDF8EA),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: _InAppSurveyColors.brandPrimary,
                    size: 24.w,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        context.l10n.home.inAppSurveyEntryTitle,
                        maxLines: 1,
                        style: AppStyle.textBold16.copyWith(color: _InAppSurveyColors.textPrimary),
                      ),
                      AppText(
                        context.l10n.home.inAppSurveyEntrySubtitle,
                        maxLines: 1,
                        style: AppStyle.text12.copyWith(color: _InAppSurveyColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: const Color(0xFF7F8EA4),
                  size: 24.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
