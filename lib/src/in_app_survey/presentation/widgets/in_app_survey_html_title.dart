part of '../../in_app_survey.dart';

class _InAppSurveyTitle extends StatelessWidget {
  const _InAppSurveyTitle(this.text);

  final String text;

  static const LinearGradient _titleGradient = LinearGradient(
    colors: [
      Color(0xFF4B44CA),
      Color(0xFFA052FF),
      Color(0xFFEF81D4),
      Color(0xFFFF8F8F),
      Color(0xFFFFCE66),
    ],
    stops: [
      0,
      0.25,
      0.5,
      0.75481,
      1,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppStyle.textBold20.copyWith(
      height: 1.5,
    );

    if (!text.containsHtmlTag) {
      return AppText(
        text,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.visible,
        style: _visibleTextStyle(baseStyle),
      );
    }

    final fragment = html_parser.parseFragment(text);
    final root = fragment.querySelector('h1') ?? fragment;
    final spans = _trimEdgeTextSpans(_buildInlineSpans(root.nodes, baseStyle));

    if (spans.isEmpty) {
      return AppText(
        text.stripHtmlTags,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.visible,
        style: _visibleTextStyle(baseStyle),
      );
    }

    final plainText = _plainText(spans);
    final useSingleLineFit = plainText.length <= 36 && !plainText.contains('\n');
    final richText = Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
      maxLines: useSingleLineFit ? 1 : 3,
      overflow: TextOverflow.visible,
      softWrap: !useSingleLineFit,
      textWidthBasis: useSingleLineFit ? TextWidthBasis.longestLine : TextWidthBasis.parent,
    );

    return SizedBox(
      width: double.infinity,
      child: useSingleLineFit
          ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: richText,
            )
          : richText,
    );
  }

  String _plainText(List<InlineSpan> spans) => spans.map(_spanPlainText).join();

  String _spanPlainText(InlineSpan span) {
    if (span is TextSpan) {
      return (span.text ?? '') + (span.children?.map(_spanPlainText).join() ?? '');
    }
    if (span is WidgetSpan && span.child is _GradientTitleText) {
      return (span.child as _GradientTitleText).text;
    }
    return '';
  }

  List<InlineSpan> _buildInlineSpans(List<html_dom.Node> nodes, TextStyle inheritedStyle) {
    final spans = <InlineSpan>[];

    for (final node in nodes) {
      if (node.nodeType == html_dom.Node.TEXT_NODE) {
        final value = _normalizeHtmlText(node.text);
        if (value.isNotEmpty) {
          spans.add(TextSpan(text: value, style: _visibleTextStyle(inheritedStyle)));
        }
        continue;
      }

      if (node is! html_dom.Element) continue;

      if (node.localName == 'br') {
        spans.add(TextSpan(text: '\n', style: _visibleTextStyle(inheritedStyle)));
        continue;
      }

      final style = _styleForElement(node, inheritedStyle);

      if (_shouldUseGradient(node)) {
        final value = _normalizeHtmlText(node.text);
        if (value.trim().isEmpty) continue;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _GradientTitleText(
              text: value,
              style: style,
              gradient: _titleGradient,
            ),
          ),
        );
        continue;
      }

      spans.addAll(_buildInlineSpans(node.nodes, style));
    }

    return spans;
  }

  List<InlineSpan> _trimEdgeTextSpans(List<InlineSpan> spans) {
    final trimmed = spans.toList();

    for (var index = 0; index < trimmed.length; index++) {
      final span = trimmed[index];
      if (span is! TextSpan) continue;
      final text = span.text?.trimLeft() ?? '';
      if (text.isEmpty) {
        trimmed.removeAt(index);
        index--;
        continue;
      }
      trimmed[index] = TextSpan(text: text, style: span.style);
      break;
    }

    for (var index = trimmed.length - 1; index >= 0; index--) {
      final span = trimmed[index];
      if (span is! TextSpan) continue;
      final text = span.text?.trimRight() ?? '';
      if (text.isEmpty) {
        trimmed.removeAt(index);
        continue;
      }
      trimmed[index] = TextSpan(text: text, style: span.style);
      break;
    }

    return trimmed;
  }

  String _normalizeHtmlText(String? value) => (value ?? '').replaceAll(RegExp(r'\s+'), ' ');

  TextStyle _visibleTextStyle(TextStyle style) => style.color == null ? style.copyWith(color: _InAppSurveyColors.textPrimary) : style;

  TextStyle _styleForElement(html_dom.Element element, TextStyle inheritedStyle) {
    var style = inheritedStyle;
    final tag = element.localName;

    if (tag == 'b' || tag == 'strong') style = style.copyWith(fontWeight: FontWeight.w700);
    if (tag == 'i' || tag == 'em') style = style.copyWith(fontStyle: FontStyle.italic);
    if (tag == 'u') style = style.copyWith(decoration: TextDecoration.underline);

    final inlineStyle = element.attributes['style'] ?? '';
    final fontSize = _readPxValue(inlineStyle, 'font-size');
    final fontWeight = _readFontWeight(inlineStyle);
    final color = _readHexColor(inlineStyle, 'color');

    if (fontSize != null) style = style.copyWith(fontSize: fontSize.sp);
    if (fontWeight != null) style = style.copyWith(fontWeight: fontWeight);
    if (color != null) style = style.copyWith(color: color);

    return style;
  }

  bool _shouldUseGradient(html_dom.Element element) {
    final dataGradient = element.attributes['data-gradient']?.trim();
    final inlineStyle = element.attributes['style']?.toLowerCase() ?? '';

    return (dataGradient != null && dataGradient.isNotEmpty) ||
        inlineStyle.contains('linear-gradient') ||
        inlineStyle.contains('background-clip: text') ||
        inlineStyle.contains('-webkit-text-fill-color: transparent');
  }
}
