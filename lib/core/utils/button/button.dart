part of '../utils.dart';

enum DButtonType {
  fill,
  outline,
  text,
}

class DButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final Size? size;
  final TextStyle? style;
  final int expandedFlex;
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final Color? textColor;
  final BorderSide? borderSide;
  final DButtonType buttonType;
  final double? elevation;
  final OutlinedBorder? shape;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Widget? customChild;
  final MaterialTapTargetSize? tapTargetSize;
  final VisualDensity? visualDensity;
  final Alignment? alignment;
  final bool isLoading;

  const DButton({
    super.key,
    this.text = 'Button',
    required this.onPressed,
    this.size,
    this.style,
    this.expandedFlex = 0,
    this.backgroundColor,
    this.surfaceTintColor,
    this.borderSide,
    this.buttonType = DButtonType.fill,
    this.elevation,
    this.shape,
    this.textColor,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.tapTargetSize,
    this.visualDensity,
    this.alignment,
    this.customChild,
    this.isLoading = false,
  }) : assert(borderSide == null || buttonType == DButtonType.outline, 'borderSideColor can only be used with DButtonType.secondary');

  // isLoading always wins over a passed-in onPressed/child: the caller may
  // race a rebuild between "still loading" and "handler cleared" — forcing
  // both here means there's no frame where the button is both spinning and
  // tappable, or tappable while a request is genuinely still in flight.
  Function()? get _effectiveOnPressed => isLoading ? null : onPressed;

  Widget get _effectiveChild {
    if (isLoading) {
      final Color spinnerColor = textColor ?? AppColorLight.surface;
      return SizedBox(width: 20.w, height: 20.w, child: CircularProgressIndicator(strokeWidth: 2, color: spinnerColor));
    }
    return customChild ?? AppText(text, style: style ?? AppStyle.textBold22.copyWith(color: textColor ?? AppColorLight.surface));
  }

  Widget get btnWidget {
    Map<DButtonType, Widget> buttonTypeMap = {
      DButtonType.fill: FilledButton(
        onPressed: _effectiveOnPressed,
        style: FilledButton.styleFrom(
          iconAlignment: IconAlignment.start,
          tapTargetSize: tapTargetSize,
          visualDensity: visualDensity,
          alignment: alignment,
          padding: padding.w,
          backgroundColor: backgroundColor,
          surfaceTintColor: surfaceTintColor,
          elevation: elevation,
          shape: shape,
          minimumSize: size ?? Size.fromHeight(50.h),
        ),
        child: _effectiveChild,
      ),
      DButtonType.outline: OutlinedButton(
        onPressed: _effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          tapTargetSize: tapTargetSize,
          visualDensity: visualDensity,
          alignment: alignment,
          padding: padding.w,
          backgroundColor: backgroundColor,
          surfaceTintColor: surfaceTintColor,
          elevation: elevation,
          shape: shape,
          side: borderSide,
          minimumSize: size ?? Size.fromHeight(50.h),
        ),
        child: _effectiveChild,
      ),
      DButtonType.text: TextButton(
        onPressed: _effectiveOnPressed,
        style: TextButton.styleFrom(
          tapTargetSize: tapTargetSize,
          visualDensity: visualDensity,
          alignment: alignment,
          padding: padding.w,
          backgroundColor: backgroundColor,
          surfaceTintColor: surfaceTintColor,
          elevation: elevation,
          shape: shape,
          minimumSize: size ?? Size.fromHeight(50.h),
        ),
        child: _effectiveChild,
      ),
    };

    return buttonTypeMap[buttonType]!;
  }

  @override
  Widget build(BuildContext context) {
    Widget tmp = btnWidget;

    if (margin != EdgeInsets.zero) tmp = Container(margin: margin, child: tmp);

    if (expandedFlex > 0) tmp = Expanded(flex: expandedFlex, child: tmp);

    return tmp;
  }
}
