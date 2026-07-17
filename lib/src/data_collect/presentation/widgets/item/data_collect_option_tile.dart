part of '../../../data_collect.dart';

enum DataCollectOptionType { radio, checkbox, none }

class DataCollectOptionTile extends StatelessWidget {
  const DataCollectOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.type = DataCollectOptionType.radio,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.leadingIconSize = 24,
    this.enableLeading = true,
  });

  final OnboardOptionEntity option;
  final bool isSelected;
  final VoidCallback onTap;
  final DataCollectOptionType type;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double leadingIconSize;
  final bool enableLeading;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary;
    final background = isSelected ? AppCustomColor.backgroundWhite : AppCustomColor.backgroundGray;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptic.select();
        onTap();
      },
      child: Container(
        constraints: BoxConstraints(minHeight: 54.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 2.w),
        ),
        child: Row(
          crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (enableLeading && option.icon.isNotEmpty)
              CacheNetworkGraphic(
                url: option.icon,
                width: leadingIconSize.w,
                height: leadingIconSize.h,
              ),
            if (enableLeading && option.icon.isNotEmpty) 16.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    option.label.text,
                    maxLines: 2,
                    style: (titleStyle ?? _defaultTitleStyle).copyWith(
                      color: isSelected ? AppCustomColor.textPrimary : AppCustomColor.textTertiary,
                      fontWeight: isSelected ? FontWeight.w700 : titleStyle?.fontWeight ?? FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    4.verticalSpace,
                    AppText(
                      subtitle!,
                      maxLines: 2,
                      style: (subtitleStyle ?? _defaultSubtitleStyle).copyWith(
                        color: isSelected ? AppCustomColor.textSecondary : AppCustomColor.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (type != DataCollectOptionType.none) 8.horizontalSpace,
            switch (type) {
              DataCollectOptionType.radio => CustomRadio(isSelected: isSelected),
              DataCollectOptionType.checkbox => isSelected ? Icon(Icons.check_rounded, color: AppCustomColor.brandPrimary, size: 22.sp) : SizedBox.square(dimension: 24.w),
              DataCollectOptionType.none => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }

  TextStyle get _defaultTitleStyle => AppStyle.text16.copyWith(fontWeight: FontWeight.w600);

  TextStyle get _defaultSubtitleStyle => AppStyle.text12.copyWith(fontWeight: FontWeight.w400);
}
