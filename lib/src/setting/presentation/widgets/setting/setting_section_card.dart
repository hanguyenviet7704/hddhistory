part of '../../../setting.dart';

class SettingSectionCard extends StatelessWidget {
  const SettingSectionCard({super.key, this.title, required this.children});

  /// Null/empty renders the card with no header, which is what the account
  /// card at the bottom of Settings needs (design `Settings`).
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((title ?? '').isNotEmpty) ...[
          Text(
            title!,
            style: AppStyle.text14.copyWith(
              // Section labels ("Chung" / "Giới thiệu") sit directly on the page
              // background, so they follow the study theme; everything inside the
              // card below keeps its own dark ink.
              color: studyThemeOnBg(context, AppCustomColor.textTertiary),
            ),
          ),
          SizedBox(height: 12.h),
        ],
        Container(
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppCustomColor.borderDefault,
                blurRadius: 2,
                offset: Offset.zero,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
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
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      color: AppCustomColor.borderDefault,
    );
  }
}

class SettingOptionTile extends StatelessWidget {
  const SettingOptionTile({
    super.key,
    this.iconAsset,
    this.iconWidget,
    required this.title,
    this.trailingText,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.trailingTextColor,
    this.iconBackgroundColor,
    this.showChevron = true,
    this.isLoading = false,
  });

  /// One of [iconAsset] or [iconWidget] must be given.
  final String? iconAsset;

  /// Escape hatch for rows whose glyph is not in the SVG bundle (sign in,
  /// delete account). Takes precedence over [iconAsset].
  final Widget? iconWidget;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Color? trailingTextColor;
  final Color? iconBackgroundColor;
  final bool showChevron;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final String? trailing = trailingText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading || onTap == null
            ? null
            : () {
                AppHaptic.select();
                onTap!.call();
              },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (iconWidget != null)
                SizedBox(width: 24.w, height: 24.w, child: Center(child: iconWidget))
              else if (iconBackgroundColor != null)
                _SettingIcon(
                  asset: iconAsset!,
                  backgroundColor: iconBackgroundColor!,
                  color: iconColor ?? AppCustomColor.iconPrimary,
                )
              else
                SvgPicture.asset(
                  iconAsset!,
                  width: 24.w,
                  height: 24.w,
                  colorFilter: ColorFilter.mode(
                    iconColor ?? AppCustomColor.iconPrimary,
                    BlendMode.srcIn,
                  ),
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
              // isLoading replaces the trailing text/chevron with a spinner
              // instead of adding a 4th indicator — this row has no other
              // affordance-sized slot to put one in without reflowing layout.
              if (isLoading) ...[
                SizedBox(width: 12.w),
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppCustomColor.brandPrimary),
                ),
              ] else ...[
                if (trailing != null && trailing.isNotEmpty) ...[
                  SizedBox(width: 12.w),
                  Text(
                    trailing,
                    style: AppStyle.textBold14.copyWith(
                      // Inside a glass card the pale tertiary slate loses
                      // contrast against the background bleeding through.
                      color: trailingTextColor ?? studyThemeCardMuted(context, AppCustomColor.textTertiary),
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
            ],
          ),
        ),
      ),
    );
  }
}

class SettingSwitchTile extends StatelessWidget {
  const SettingSwitchTile({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.value,
    this.onChanged,
    this.isLoading = false,
  });

  final String iconAsset;
  final String title;
  final bool value;
  final bool isLoading;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged == null
            ? null
            : () {
                AppHaptic.select();
                onChanged!.call(!value);
              },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 24.w,
                height: 24.w,
                colorFilter: ColorFilter.mode(AppCustomColor.iconPrimary, BlendMode.srcIn),
              ),
              SizedBox(width: 12.w),
              AppText(
                title,
                style: AppStyle.textBold14.copyWith(
                  color: AppCustomColor.textPrimary,
                ),
              ),
              Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppCustomColor.brandPrimary,
                        ),
                      )
                    : Switch.adaptive(
                        key: const Key('setting_notification_toggle'),
                        value: value,
                        onChanged: onChanged,
                        activeTrackColor: AppCustomColor.brandPrimary,
                      ),
              ),
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
