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
    this.padding,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? iconPath;

  /// Dòng phụ dưới nhãn (S4 lĩnh vực). Bỏ qua khi null/rỗng.
  final String? subtitle;

  /// Vòng tròn ✓ bên phải khi được chọn. Tắt ở lưới tuổi (S3) — ô hẹp, chỉ cần
  /// viền là đủ tín hiệu.
  final bool trailingCheck;

  /// Căn giữa nội dung (lưới tuổi 2 cột).
  final bool centered;

  /// Design cho mỗi màn một cỡ đệm khác nhau: ô tuổi cao và hẹp (18/8), hàng
  /// lĩnh vực thấp vì đã có icon (12/16), hàng mong muốn ở giữa (15/16). Bỏ
  /// trống thì lấy cỡ của hàng mong muốn.
  final EdgeInsets? padding;

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
        padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: borderRadius,
          border: selected
              ? GradientBoxBorder(gradient: OnboardV2GradientText.gradient, width: 1.5.w)
              : Border.all(color: AppCustomColor.borderSecondary, width: 1.5.w),
        ),
        child: Row(
          mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (icon != null && icon.isNotEmpty) ...[
              // Design vẽ icon trần 28px, không có ô nền xám — chính cái ô 48px
              // cũ là thứ làm mỗi hàng cao hơn bản vẽ gần một phần ba.
              SizedBox(
                width: 28.w,
                height: 28.w,
                child: CacheNetworkGraphic(url: icon, fit: BoxFit.contain),
              ),
              14.horizontalSpace,
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
                      fontSize: 15.sp,
                      color: selected ? AppCustomColor.brandPrimary : AppCustomColor.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  if (subtitleText != null && subtitleText.isNotEmpty) ...[
                    3.verticalSpace,
                    AppText(
                      subtitleText,
                      textAlign: centered ? TextAlign.center : TextAlign.start,
                      overflow: TextOverflow.visible,
                      style: AppStyle.text12.copyWith(
                        color: selected ? const Color(0xFFCF9E22) : AppCustomColor.onboardMutedLabel,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected && trailingCheck) ...[
              12.horizontalSpace,
              Container(
                width: 22.w,
                height: 22.w,
                decoration: const BoxDecoration(color: AppCustomColor.brandPrimary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(Icons.check_rounded, size: 13.w, color: AppCustomColor.textWhite),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
