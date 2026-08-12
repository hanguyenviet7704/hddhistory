part of '../../../monetization.dart';

class _PurchaseButton extends StatelessWidget {
  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  /// 54 on the full page, 60 on the compact sheet — the design sizes the CTA to
  /// how much else is competing with it on the surface.
  final double? height;

  const _PurchaseButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: Container(
        width: double.infinity,
        height: height ?? 54.h,
        decoration: BoxDecoration(
          // Premium design: solid #5A52F0, not the old gradient. The HTML also
          // carries `inset 0 -3px rgba(0,0,0,.12)` — Flutter's BoxShadow cannot
          // inset, and a 3px inner shelf under a solid fill is not worth a
          // Stack, so only the outer shadow is kept.
          color: const Color(0xFF5A52F0),
          borderRadius: BorderRadius.circular(1000.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A52F0).withValues(alpha: 0.4),
              blurRadius: 34,
              offset: const Offset(0, 16),
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
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.18,
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
