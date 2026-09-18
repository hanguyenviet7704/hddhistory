part of '../../../onboard_v2.dart';

class OnboardV2SelectableOptionRow extends StatelessWidget {
  const OnboardV2SelectableOptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconPath,
    this.subtitle,
    this.trailingCheck = true,
    this.centered = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? iconPath;

  /// Dòng phụ dưới nhãn (S4 lĩnh vực). Bỏ qua khi null/rỗng.
  final String? subtitle;

  /// Vòng tròn ✓ bên phải khi được chọn. Tắt ở lưới tuổi (S3) — ô hẹp, chỉ cần
  /// viền gradient là đủ tín hiệu.
  final bool trailingCheck;

  /// Căn giữa nội dung (lưới tuổi 2 cột).
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final icon = iconPath?.trim();
    final subtitleText = subtitle?.trim();
    final borderRadius = BorderRadius.circular(16.r);
    return InkWell(
      onTap: () {
        AppHaptic.select();
        onTap();
      },
      borderRadius: borderRadius,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: borderRadius,
          border: selected ? GradientBoxBorder(gradient: OnboardV2GradientText.gradient, width: 2.w) : Border.all(color: AppCustomColor.borderSecondary, width: 2.w),
        ),
        child: Row(
          mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (icon != null && icon.isNotEmpty) ...[
              Container(
                width: 48.w,
                height: 48.w,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundGray,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: CacheNetworkGraphic(url: icon, fit: BoxFit.cover),
              ),
              12.horizontalSpace,
            ],
            Flexible(
              fit: centered ? FlexFit.loose : FlexFit.tight,
              child: Column(
                crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    label,
                    textAlign: centered ? TextAlign.center : TextAlign.start,
                    overflow: TextOverflow.visible,
                    style: AppStyle.text16.copyWith(
                      color: selected ? AppCustomColor.textPrimary : AppCustomColor.textSecondary,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  if (subtitleText != null && subtitleText.isNotEmpty) ...[
                    2.verticalSpace,
                    AppText(
                      subtitleText,
                      textAlign: centered ? TextAlign.center : TextAlign.start,
                      overflow: TextOverflow.visible,
                      style: AppStyle.text12.copyWith(
                        color: selected ? AppCustomColor.brandPrimary.op(0.8) : AppCustomColor.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected && trailingCheck) ...[
              12.horizontalSpace,
              Icon(Icons.check_circle, size: 24.w, color: AppCustomColor.brandPrimary),
            ],
          ],
        ),
      ),
    );
  }
}
