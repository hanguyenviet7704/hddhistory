part of '../utils.dart';

// ignore: must_be_immutable
class AppButton extends StatelessWidget {
  Widget? child;
  final VoidCallback? onPressed;
  EdgeInsets? padding;
  BorderRadius? borderRadius;
  final bool fullWidthBtn;
  final bool disabled;
  final bool isTransparent;
  String? icon;
  TextStyle? textStyle;
  Decoration? decoration;
  double? _minWidth;
  final double? height;
  final double? width;
  double? paddingLeftIcon;

  AppButton({
    super.key,
    this.borderRadius,
    this.padding,
    this.child,
    this.onPressed,
    this.fullWidthBtn = false,
    this.disabled = false,
    this.isTransparent = false,
    this.decoration,
    this.height,
    this.icon,
    this.width,
  });

  AppButton.primary({
    super.key,
    this.child,
    this.onPressed,
    this.borderRadius,
    this.padding,
    this.fullWidthBtn = false,
    this.disabled = false,
    this.decoration,
    this.isTransparent = false,
    this.height,
    this.width,
  }) {
    decoration =
        decoration ??
        ShapeDecoration(
          shape: RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(100.r)),
          color: _bgColorPrimary.op(disabled ? .2 : 1),
        );
    textStyle = AppStyle.textBold20.apply(color: _colorTextPrimary.op(disabled ? .5 : 1));
    _minWidth = 140.w;
  }

  AppButton.primaryWithIcon({
    super.key,
    this.child,
    this.onPressed,
    this.borderRadius,
    this.padding,
    this.fullWidthBtn = false,
    this.disabled = false,
    this.decoration,
    this.isTransparent = false,
    this.icon,
    this.height,
    this.width,
    this.paddingLeftIcon,
  }) {
    decoration =
        decoration ??
        ShapeDecoration(
          shape: RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(100.r)),
          color: _bgColorPrimary.op(disabled ? .2 : 1),
        );
    textStyle = AppStyle.textBold20.apply(color: _colorTextPrimary.op(disabled ? .5 : 1));
    _minWidth = 140.w;
  }

  AppButton.secondary({
    super.key,
    this.child,
    this.onPressed,
    this.borderRadius,
    this.padding,
    this.fullWidthBtn = false,
    this.disabled = false,
    this.decoration,
    this.isTransparent = false,
    this.height,
    this.width,
  }) {
    decoration =
        decoration ??
        ShapeDecoration(
          shape: RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(100.r)),
          color: _bgColorSecondary.op(disabled ? .2 : 1),
        );
    textStyle = AppStyle.textBold20.apply(color: _colorTextSecondary.op(disabled ? .5 : 1));
    _minWidth = 140.w;
  }

  AppButton.secondaryWithIcon({
    super.key,
    this.child,
    this.onPressed,
    this.borderRadius,
    this.padding,
    this.fullWidthBtn = false,
    this.disabled = false,
    this.decoration,
    this.isTransparent = false,
    this.icon,
    this.height,
    this.width,
  }) {
    decoration =
        decoration ??
        ShapeDecoration(
          shape: RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(100.r)),
          color: _bgColorSecondary.op(disabled ? .2 : 1),
        );
    textStyle = AppStyle.textBold20.apply(color: _colorTextSecondary.op(disabled ? .5 : 1));
    _minWidth = 140.w;
  }

  Color get _colorTextPrimary => Colors.white;

  Color get _colorTextSecondary => Color(0xFF7F8EA4);

  Color get _bgColorPrimary => Color(0xFFB5860F);

  Color get _bgColorSecondary => Color(0xFFE3E8EF);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = _minWidth ?? 0;
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : double.infinity;
        final effectiveMinWidth = maxWidth.isFinite ? min(minWidth, maxWidth) : minWidth;
        return Container(
          decoration: decoration,
          width: fullWidthBtn ? double.infinity : width,
          height: height,
          constraints: BoxConstraints(minWidth: effectiveMinWidth),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(100.r),
            child: MaterialButton(
              elevation: 0,
              color: Colors.transparent,
              highlightElevation: 0,
              hoverElevation: 0,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minWidth: 0,
              height: 0,
              splashColor: isTransparent ? Colors.transparent : null,
              highlightColor: isTransparent ? Colors.transparent : null,
              padding: padding ?? EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
              // App-wide tap haptic (mirrors DButton) — every AppButton press
              // gets the same light impact without each call site adding it.
              onPressed: !disabled && onPressed != null
                  ? () {
                      AppHaptic.select();
                      onPressed!();
                    }
                  : null,
              child:
                  icon == null
                      ? (child ?? const SizedBox.shrink())
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(child: child ?? const SizedBox.shrink()),
                            Padding(
                              padding: EdgeInsets.only(left: paddingLeftIcon ?? 12.w),
                              child: SvgPicture.asset(
                                icon!,
                                colorFilter: ColorFilter.mode(
                                  textStyle?.color ?? _colorTextPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        );
      },
    );
  }
}
