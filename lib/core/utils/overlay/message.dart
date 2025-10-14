part of '../utils.dart';

class OverlayMessage extends StatelessWidget {
  final String message;
  final Widget? messageWidget;
  final MessageType type;
  final Duration duration;
  final SnackBarAction? action;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final double elevation;
  final DismissDirection? dismissDirection;
  final VoidCallback? onVisible;
  final VoidCallback? onTap;
  final ShapeBorder shape;
  final bool showCloseIcon;
  final Color? closeIconColor;
  final double? width;
  final AlignmentGeometry messageAlignment;
  final double leadingSpace;
  final double trailingSpace;

  OverlayMessage({
    super.key,
    this.message = '',
    this.messageWidget,
    this.type = MessageType.danger,
    this.duration = const Duration(seconds: 3),
    this.action,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
    this.elevation = 1.5,
    this.dismissDirection,
    this.onVisible,
    this.onTap,
    this.shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    this.showCloseIcon = true,
    this.closeIconColor,
    this.width,
    this.messageAlignment = Alignment.topCenter,
    this.leadingSpace = 10,
    this.trailingSpace = 14,
  }) : assert(message.isNotEmpty || messageWidget != null, 'Message or messageWidget must not be null or empty');

  /// Get slide direction based on message alignment
  Offset _getSlideBegin() {
    return switch (messageAlignment) {
      Alignment.topCenter => const Offset(0, -1),
      Alignment.bottomCenter => const Offset(0, 1),
      _ => const Offset(0, -1),
    };
  }

  void _init() {
    if (onVisible == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onVisible!();
    });
  }

  @override
  Widget build(BuildContext context) {
    _init();

    return Align(
          alignment: messageAlignment,
          child: InkWell(
            onTap: onTap,
            child: Container(
              margin: margin,
              padding: padding.w,
              width: width,
              constraints: BoxConstraints(
                maxWidth: 1.sw - margin.horizontal,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: (shape as RoundedRectangleBorder).borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: type.color.op(0.3),
                    blurRadius: elevation * 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...messageWidget != null
                      ? [messageWidget!]
                      : [
                          SvgPicture.asset(
                            type.svgIcon,
                            colorFilter: ColorFilter.mode(type.color, BlendMode.srcIn),
                            width: 21.5.w,
                            height: 21.5.w,
                          ),
                          leadingSpace.horizontalSpace,
                          AppText(
                            message,
                            style: AppStyle.text18.copyWith(color: type.color),
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            expandedType: ExpandedType.flex,
                            expandFlex: 1,
                          ),
                          if (showCloseIcon) ...[
                            trailingSpace.horizontalSpace,
                            InkWell(
                              onTap: () => DOverlay.removeOverlay(),
                              child: Icon(Icons.close_rounded, color: closeIconColor),
                            ),
                          ],
                        ],
                ],
              ),
            ),
          ),
        )
        .animate()
        .slideY(
          begin: _getSlideBegin().dy,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeInOutCirc,
        )
        .fadeIn(
          duration: 600.ms,
          curve: Curves.easeInOutCirc,
        )
        .then(delay: duration)
        .slideY(
          begin: 0,
          end: _getSlideBegin().dy,
          duration: 600.ms,
          curve: Curves.easeInOutCirc,
        )
        .fadeOut(
          duration: 600.ms,
          curve: Curves.easeInOutCirc,
        )
        .callback(callback: (_) => DOverlay.removeOverlay());
  }
}
