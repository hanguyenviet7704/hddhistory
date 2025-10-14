part of '../utils.dart';

// ignore: must_be_immutable
class AppIconButton extends StatelessWidget {
  String? iconPath;
  final double? sizeIcon;
  Color? colorIcon;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  VoidCallback? onPressed;
  final Color? backgroundColor;
  final double? elevation;
  final Size? minimumSize;

  AppIconButton({
    super.key,
    required this.iconPath,
    this.sizeIcon,
    this.colorIcon,
    this.padding,
    this.borderRadius,
    this.onPressed,
    this.backgroundColor,
    this.elevation,
    this.minimumSize,
  });

  // Constructor cho close button tương tự close_widget.dart
  AppIconButton.close({
    super.key,
    this.onPressed,
    this.sizeIcon,
    this.colorIcon,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.elevation,
    this.minimumSize,
  }) {
    iconPath = AppAsset.svg.app.icClose;
    onPressed ??= () => AppConfig.instance.context?.back();
  }

  AppIconButton.back({
    super.key,
    this.onPressed,
    this.sizeIcon,
    this.colorIcon,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.elevation,
    this.minimumSize,
  }) {
    iconPath = AppAsset.svg.app.icArrowLeft;
    colorIcon ??= Colors.white;
    onPressed ??= () => AppConfig.instance.context?.back();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(100.r),
      ),
      padding: padding ?? EdgeInsets.all(8.w),
      minWidth: 0,
      color: backgroundColor,
      elevation: elevation ?? 0,
      highlightElevation: 0,
      hoverElevation: 0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      child: SvgPicture.asset(
        iconPath ?? '',
        width: sizeIcon ?? 40.w,
        height: sizeIcon ?? 40.w,
        colorFilter: colorIcon != null ? ColorFilter.mode(colorIcon!, BlendMode.srcIn) : null,
      ),
    );
  }
}
