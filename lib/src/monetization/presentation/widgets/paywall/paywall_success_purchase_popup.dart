part of '../../../monetization.dart';

class PaywallSuccessPurchasePopup extends StatelessWidget {
  const PaywallSuccessPurchasePopup({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppCustomColor.bottomSheetScrim,
      builder: (_) => const PaywallSuccessPurchasePopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(28.w, 56.h, 28.w, 34.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 60,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  l10n.monetization.successTitle,
                  textAlign: TextAlign.center,
                  style: AppStyle.text20.copyWith(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: AppCustomColor.textPrimary,
                    height: 1.3,
                  ),
                ),
                12.verticalSpace,
                AppText(
                  l10n.monetization.successDescription,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: AppStyle.text14.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5F6F86),
                    height: 1.55,
                  ),
                ),
                28.verticalSpace,
                // Sized to its label (with a floor) rather than edge to edge —
                // the design keeps this dialog's CTA compact so the card reads
                // as a note, not another paywall.
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 200.w),
                  child: Container(
                    height: 56.h,
                    padding: EdgeInsets.symmetric(horizontal: 34.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB5860F),
                      borderRadius: BorderRadius.circular(1000.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB5860F).withValues(alpha: 0.3),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          AppHaptic.success();
                          AppService.instance.appTrackingService.trackPaywallSuccessPopupClick();
                          Navigator.of(context).maybePop();
                        },
                        borderRadius: BorderRadius.circular(1000.r),
                        // widthFactor pins the Center to its label; a bare
                        // Center expands to every width it is offered, which
                        // would stretch this back to a full-width bar.
                        child: Center(
                          widthFactor: 1,
                          child: AppText(
                            l10n.monetization.successCta,
                            style: AppStyle.text16.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Half in, half out: the design hangs an 84 badge 42 above the card
            // edge, and the card's own top padding (56) is what this Stack
            // measures from — hence 56 + 42.
            Positioned(
              top: -(56 + 42).h,
              child: Image.asset(
                AppAsset.images.app.successDecoration.path,
                height: 84.h,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
