part of '../utils.dart';

enum ExpandedType {
  flex,
  expanded,
}

class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final double textScaleFactor;
  final int maxLines;
  final TextWidthBasis textWidthBasis;
  final bool enableTooltip;
  final void Function()? onTap;
  final int expandFlex;
  final EdgeInsets margin;
  final double width;
  final bool enableFitScaleDown;
  final ExpandedType expandedType;
  final bool? softWrap;

  // HTML-specific properties
  final bool forceHtmlRendering;
  final EdgeInsetsGeometry htmlPadding;
  final bool enableHtmlLinks;

  const AppText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.ellipsis,
    this.textScaleFactor = 1,
    this.maxLines = 1,
    this.textWidthBasis = TextWidthBasis.parent,
    this.enableTooltip = false,
    this.onTap,
    this.expandFlex = 0,
    this.margin = EdgeInsets.zero,
    this.width = 0,
    this.enableFitScaleDown = false,
    this.expandedType = ExpandedType.expanded,
    this.forceHtmlRendering = false,
    this.htmlPadding = EdgeInsets.zero,
    this.enableHtmlLinks = true,
    this.softWrap,
  }) : assert(maxLines > 0, 'maxLines must be greater than 0'),
       assert(expandFlex >= 0, 'expandFlex must be greater than or equal to 0'),
       assert(width >= 0, 'width must be greater than or equal to 0'),
       assert(!(expandFlex > 0 && width > 0), 'expandFlex and width cannot be used together'),
       assert(!(expandFlex > 0 && enableFitScaleDown), 'expandFlex and enableFitScaleDown cannot be used together');

  Widget get child {
    final bool shouldRenderAsHtml = forceHtmlRendering || text.containsHtmlTag;

    if (shouldRenderAsHtml) {
      return _buildHtmlWidget();
    }

    return _buildTextWidget();
  }

  Widget _buildHtmlWidget() {
    try {
      return Container(
        padding: htmlPadding,
        child: HtmlWidget(
          text,
          textStyle: style ?? AppStyle.text14,
          onTapUrl: enableHtmlLinks
              ? (url) {
                  // Handle URL taps - you can customize this behavior
                  return true;
                }
              : null,
          renderMode: RenderMode.column,
          enableCaching: true,
        ),
      );
    } catch (e) {
      // Fallback to regular text widget if HTML parsing fails
      return _buildTextWidget();
    }
  }

  Widget _buildTextWidget() {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap ?? maxLines != 1,
      textScaler: TextScaler.linear(textScaleFactor),
      style: style ?? AppStyle.text14,
      textWidthBasis: textWidthBasis,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget tmpText = child;

    if (enableTooltip) {
      tmpText = Tooltip(
        showDuration: const Duration(seconds: 1),
        message: text.containsHtmlTag ? text.stripHtmlTags : text,
        child: tmpText,
      );
    }

    if (onTap != null) {
      tmpText = GestureDetector(
        onTap: onTap,
        child: tmpText,
      );
    }

    if (margin != EdgeInsets.zero) {
      tmpText = Container(
        margin: margin,
        child: tmpText,
      );
    }

    if (expandFlex > 0) {
      if (expandedType == ExpandedType.flex) {
        tmpText = Flexible(flex: expandFlex, child: tmpText);
      } else {
        tmpText = Expanded(flex: expandFlex, child: tmpText);
      }
    }

    if (width > 0) {
      tmpText = SizedBox(
        width: width,
        child: tmpText,
      );
    }

    if (enableFitScaleDown) {
      tmpText = FittedBox(
        fit: BoxFit.scaleDown,
        child: tmpText,
      );
    }

    return tmpText;
  }
}
