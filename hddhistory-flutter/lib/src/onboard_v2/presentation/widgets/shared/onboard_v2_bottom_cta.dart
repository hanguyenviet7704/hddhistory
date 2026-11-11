part of '../../../onboard_v2.dart';

class OnboardV2BottomCta extends StatelessWidget {
  const OnboardV2BottomCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.hasGlow = false,
    this.mutedSecondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  /// Quầng tím dưới nút. Design chỉ bật ở những màn có một hành động dứt điểm
  /// (S1 mở đầu, S8 bật thông báo, S10 chọn khoá), không bật ở các màn hỏi.
  final bool hasGlow;

  /// Nút phụ màu xám nhạt thay vì màu thương hiệu — design dùng cho "Để sau".
  final bool mutedSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 56.h,
          decoration: hasGlow && !isLoading && onPressed != null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(1000.r),
                  boxShadow: [
                    BoxShadow(color: AppCustomColor.brandPrimary.op(0.32), blurRadius: 22.r, offset: Offset(0, 10.h)),
                  ],
                )
              : null,
          child: ElevatedButton(
            key: const Key('onboard_v2_primary_cta'),
            onPressed: isLoading || onPressed == null
                ? null
                : () {
                    AppHaptic.select();
                    onPressed!();
                  },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppCustomColor.brandPrimary,
              disabledBackgroundColor: AppCustomColor.buttonDisable,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.r)),
            ),
            child: isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : AppText(
                    label,
                    style: AppStyle.text16.copyWith(
                      color: onPressed == null ? AppCustomColor.textTertiary : AppCustomColor.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        if (secondaryLabel != null) ...[
          10.verticalSpace,
          TextButton(
            key: const Key('onboard_v2_secondary_cta'),
            onPressed: isLoading || onSecondaryPressed == null
                ? null
                : () {
                    AppHaptic.select();
                    onSecondaryPressed!();
                  },
            child: AppText(
              secondaryLabel!,
              style: AppStyle.text14.copyWith(
                fontSize: mutedSecondary ? 15.sp : 14.sp,
                color: mutedSecondary ? AppCustomColor.onboardMutedLabel : AppCustomColor.brandPrimary,
                fontWeight: mutedSecondary ? FontWeight.w600 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
