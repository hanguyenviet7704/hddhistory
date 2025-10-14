part of '../monetization.dart';

class PremiumPopupProductionUnlock extends StatelessWidget {
  const PremiumPopupProductionUnlock({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.text.close,
      transitionBuilder: (_, animation, _, child) {
        final curved = Curves.easeOutBack.transform(animation.value);
        return Transform.scale(
          scale: curved,
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => const PremiumPopupProductionUnlock(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: 620.w,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0xFFF1B491).withValues(alpha: 0.2),
                blurRadius: 24,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header with title and close button
                  Image.asset(
                    AppAsset.images.userPurchaseDecoration.path,
                    width: 720.w,
                  ),
                  40.verticalSpace,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppText(
                          '🎉 ${context.text.monetPopupUpgradeSucceedTitle}',
                          style: AppStyle.textBold32,
                        ),
                        8.verticalSpace,
                        AppText(
                          context.text.monetPopupUpgradeSucceedSubtitle1,
                          style: AppStyle.text20,
                        ),
                        AppText(
                          context.text.monetPopupUpgradeSucceedSubtitle2,
                          style: AppStyle.text20,
                        ),
                        32.verticalSpace,
                        // Action buttons
                        AppButton.primary(
                          width: 324.w,
                          child: context.text.monetPopupUpgradeSucceedSubtitlePrimaryButton,
                          onPressed: () {
                            AppService.instance.appTrackingServiceNew.trackDrawRoadmapLoginReminder2Click(context, true);
                            context.back();
                            LoginRoute().push(context);
                          },
                        ),
                        16.verticalSpace,
                        AppText(
                          '*${context.text.monetPopupUpgradeSucceedDisclaimer}',
                          style: AppStyle.text20.copyWith(color: AppCustomColor.grey69),
                        ),
                        24.verticalSpace,
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 20.w,
                right: 20.w,
                child: CloseOverlayButton(
                  onPressed: () {
                    AppService.instance.appTrackingServiceNew.trackDrawRoadmapLoginReminder2Click(context, false);
                    context.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
