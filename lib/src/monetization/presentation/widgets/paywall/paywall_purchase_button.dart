part of '../../../monetization.dart';

class _PurchaseButton extends StatelessWidget {
  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  const _PurchaseButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: Container(
        width: double.infinity,
        height: 58.h,
        decoration: BoxDecoration(
          // Design: linear-gradient(135deg, #6C63FF, #554FF0).
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppCustomColor.paywallCtaGradientStart,
              AppCustomColor.brandPrimary,
            ],
          ),
          borderRadius: BorderRadius.circular(1000.r),
          boxShadow: [
            BoxShadow(
              color: AppCustomColor.brandPrimary.withValues(alpha: 0.35),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled
                ? () {
                    AppHaptic.success();
                    onTap();
                  }
                : null,
            borderRadius: BorderRadius.circular(1000.r),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: AppText(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        // Now carries the plan price, so it must survive a long
                        // total (e.g. "1.199.000đ") without clipping.
                        enableFitScaleDown: true,
                        style: AppStyle.text16.copyWith(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
