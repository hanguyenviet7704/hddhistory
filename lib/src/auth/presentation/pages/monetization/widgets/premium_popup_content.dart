part of '../monetization.dart';

class PremiumPopupContent extends StatelessWidget {
  const PremiumPopupContent({super.key});

  static void show(BuildContext context) {
    showGeneralDialog<bool>(
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
      pageBuilder: (context, animation, secondaryAnimation) => const PremiumPopupContent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: 620.w,
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFF1B491).withValues(alpha: 0.2),
              blurRadius: 24,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(AppAsset.images.premiumLightning.path, width: 91.w),
                8.horizontalSpace,
                AppIconButton.close(
                  onPressed: () => context.back(),
                  sizeIcon: 32.w,
                  colorIcon: AppCustomColor.secondary,
                  padding: EdgeInsets.all(8.w),
                  borderRadius: BorderRadius.circular(100),
                ),
              ],
            ),
            14.verticalSpace,
            AppText(
              context.text.monetGoPremiumPopupTitle,
              style: AppStyle.textBold32,
            ),
            AppText(
              context.text.monetGoPremiumPopupMessage,
              style: AppStyle.text20,
            ),
            32.verticalSpace,
            // Action buttons
            AppButton.primary(
              child: context.text.monetGoPremiumPopupYesButton,
              onPressed: () {
                context.back();
                AppService.instance.appTrackingServiceNew.trackPaywallScrView(context);
                // PremiumPaywallRoute().push(context);
              },
              fullWidthBtn: true,
            ),
          ],
        ),
      ),
    );
  }
}
