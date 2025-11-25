part of '../../../setting.dart';

class SettingSectionCard extends StatelessWidget {
  const SettingSectionCard({super.key, required this.title, required this.children});

  final String title;
  final List<SettingOptionTile> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppStyle.textBold12.copyWith(
            color: AppCustomColor.textTertiary,
            letterSpacing: .2,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: AppCustomColor.textPrimary.op(.04),
                blurRadius: 40,
                offset: Offset(0, 24.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) const _SettingDivider(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingDivider extends StatelessWidget {
  const _SettingDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      color: AppCustomColor.borderDefault,
    );
  }
}

class SettingOptionTile extends StatelessWidget {
  const SettingOptionTile({
    super.key,
    required this.iconAsset,
    required this.title,
    this.trailingText,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.trailingTextColor,
    this.iconBackgroundColor,
    this.showChevron = true,
  });

  final String iconAsset;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Color? trailingTextColor;
  final Color? iconBackgroundColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final String? trailing = trailingText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SettingIcon(
                asset: iconAsset,
                backgroundColor: iconBackgroundColor ?? AppCustomColor.surfaceMuted,
                color: iconColor ?? AppCustomColor.iconPrimary,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: AppStyle.textBold14.copyWith(
                    color: titleColor ?? AppCustomColor.textPrimary,
                  ),
                ),
              ),
              if (trailing != null && trailing.isNotEmpty) ...[
                SizedBox(width: 12.w),
                Text(
                  trailing,
                  style: AppStyle.textBold14.copyWith(
                    color: trailingTextColor ?? AppCustomColor.textSecondary,
                  ),
                ),
              ],
              if (showChevron) ...[
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right,
                  size: 20.w,
                  color: AppCustomColor.iconPrimary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.asset, required this.backgroundColor, required this.color});

  final String asset;
  final Color backgroundColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        asset,
        width: 22.w,
        height: 22.w,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
