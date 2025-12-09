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
    this.duration = const Duration(seconds: 2),
    this.action,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.elevation = 1.25,
    this.dismissDirection,
    this.onVisible,
    this.onTap,
    this.shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    this.showCloseIcon = false,
    this.closeIconColor,
    this.width,
    this.messageAlignment = Alignment.topCenter,
    this.leadingSpace = 8,
    this.trailingSpace = 10,
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
                    color: type.color.op(0.18),
                    blurRadius: elevation * 4,
                    offset: const Offset(0, 2),
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
                            width: 18.w,
                            height: 18.w,
                          ),
                          leadingSpace.horizontalSpace,
                          AppText(
                            message,
                            style: AppStyle.text12.copyWith(color: type.color, height: 1.4),
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
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        )
        .then(delay: duration)
        .slideY(
          begin: 0,
          end: _getSlideBegin().dy,
          duration: 350.ms,
          curve: Curves.easeInCubic,
        )
        .fadeOut(
          duration: 350.ms,
          curve: Curves.easeInCubic,
        )
        .callback(callback: (_) => DOverlay.removeOverlay());
  }
}
