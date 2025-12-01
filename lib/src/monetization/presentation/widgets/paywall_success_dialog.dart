part of '../../monetization.dart';

class PaywallSuccessDialog extends StatelessWidget {
  final VoidCallback? onExplore;

  const PaywallSuccessDialog({super.key, this.onExplore});

  static Future<void> show(BuildContext context, {VoidCallback? onExplore}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaywallSuccessDialog(onExplore: onExplore),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            4.verticalSpace,
            Center(
              child: Icon(Icons.verified_rounded, color: AppCustomColor.brandPrimary, size: 56.w),
            ),
            16.verticalSpace,
            AppText(
              context.text.monetization.successTitle,
              style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            8.verticalSpace,
            AppText(
              context.text.monetization.successDescription,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            20.verticalSpace,
            AppButton.primary(
              onPressed: () {
                Navigator.of(context).pop();
                onExplore?.call();
              },
              fullWidthBtn: true,
              child: context.text.monetization.successCta,
            ),
          ],
        ),
      ),
    );
  }
}
