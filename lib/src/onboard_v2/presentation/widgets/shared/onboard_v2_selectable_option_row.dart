part of '../../../onboard_v2.dart';

class OnboardV2SelectableOptionRow extends StatelessWidget {
  const OnboardV2SelectableOptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconPath,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? iconPath;

  @override
  Widget build(BuildContext context) {
    final icon = iconPath?.trim();
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
            Expanded(
              child: AppText(
                label,
                overflow: TextOverflow.visible,
                style: AppStyle.text16.copyWith(
                  color: selected ? AppCustomColor.textPrimary : AppCustomColor.textSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
            if (selected) ...[
              12.horizontalSpace,
              Icon(Icons.check_circle, size: 24.w, color: AppCustomColor.brandPrimary),
            ],
          ],
        ),
      ),
    );
  }
}
