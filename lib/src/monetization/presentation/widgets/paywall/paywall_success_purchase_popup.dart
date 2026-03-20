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
        padding: EdgeInsets.fromLTRB(20.w, 52.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
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
                  style: AppStyle.text20.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
                ),
                8.verticalSpace,
                AppText(
                  l10n.monetization.successDescription,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.55),
                ),
                24.verticalSpace,
                Container(
                  width: double.infinity,
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF554FF0),
                    borderRadius: BorderRadius.circular(1000.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(1000.r),
                      child: Center(
                        child: AppText(
                          l10n.monetization.successCta,
                          style: AppStyle.text16.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: -(50 + 72 / 2).h,
              child: Image.asset(
                AppAsset.images.app.successDecoration.path,
                height: 72.h,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
