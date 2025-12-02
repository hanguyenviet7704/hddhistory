part of '../../monetization.dart';

Future<void> showPaywallSuccessDialog(
  BuildContext context, {
  required VoidCallback onCta,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 16.h + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAsset.images.app.successDecoration.image(width: 88.w, height: 88.w),
              16.verticalSpace,
              AppText(
                context.text.monetization.successTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
              ),
              8.verticalSpace,
              AppText(
                context.text.monetization.successDescription,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
              ),
              20.verticalSpace,
              AppButton.primary(
                fullWidthBtn: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onCta();
                },
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: AppText(
                  context.text.monetization.successCta,
                  style: AppStyle.textBold18.copyWith(color: AppCustomColor.textWhite),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
