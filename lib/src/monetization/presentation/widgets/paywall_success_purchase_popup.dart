part of '../../monetization.dart';

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
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Icon(Icons.close, size: 22.w, color: AppCustomColor.textTertiary),
              ),
            ),
            4.verticalSpace,
            Image.asset(
              AppAsset.images.app.successDecoration.path,
              height: 140.h,
              fit: BoxFit.contain,
            ),
            16.verticalSpace,
            AppText(
              t.monetization.successTitle,
              textAlign: TextAlign.center,
              style: AppStyle.text20.copyWith(fontWeight: FontWeight.w800, color: AppCustomColor.textPrimary),
            ),
            8.verticalSpace,
            AppText(
              t.monetization.successDescription,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.4),
            ),
            20.verticalSpace,
            AppButton.primary(
              fullWidthBtn: true,
              child: t.monetization.successCta,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
