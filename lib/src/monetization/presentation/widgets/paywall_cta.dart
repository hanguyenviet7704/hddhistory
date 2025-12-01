part of '../../monetization.dart';

class PaywallCtaSection extends StatelessWidget {
  final bool loading;
  final VoidCallback onPayNow;
  final VoidCallback onRestore;
  final String ctaLabel;
  final String restoreLabel;
  final String priceLabel;

  const PaywallCtaSection({
    super.key,
    required this.loading,
    required this.onPayNow,
    required this.onRestore,
    required this.ctaLabel,
    required this.restoreLabel,
    required this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomPadding + 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.op(0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (priceLabel.isNotEmpty)
              AppText(
                priceLabel,
                style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
              ),
            8.verticalSpace,
            AppButton.primary(
              onPressed: loading ? null : onPayNow,
              fullWidthBtn: true,
              disabled: loading,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: loading
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : ctaLabel,
            ),
            10.verticalSpace,
            TextButton(
              onPressed: onRestore,
              child: AppText(
                restoreLabel,
                style: AppStyle.text14.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
