part of '../../../onboard_v2.dart';

/// Tiêu đề có nửa sau đổ dải màu, chảy CÙNG MỘT đoạn văn với nửa đầu (S8, S10).
/// Khác [OnboardV2GradientText] — cái đó là một dòng riêng, dùng cho những màn
/// design xuống dòng hẳn (S7, S9).
class OnboardV2GradientHeading extends StatelessWidget {
  const OnboardV2GradientHeading({
    super.key,
    required this.prefix,
    required this.highlight,
    this.textAlign = TextAlign.start,
    this.fontSize = 25,
    this.maxLines = 4,
  });

  final String prefix;
  final String highlight;
  final TextAlign textAlign;
  final double fontSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final style = onboardV2HeadingStyle(fontSize: fontSize);
    final gap = prefix.endsWith(' ') || highlight.startsWith(' ') ? '' : ' ';
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dải màu được cắt theo chiều rộng cả đoạn. Trong CSS nó bám theo ô của
        // riêng đoạn tô màu, nhưng đoạn đó hay tràn nhiều dòng nên không có một
        // hình chữ nhật nào đúng cả — lấy cả đoạn là xấp xỉ gần nhất.
        final shaderRect = Rect.fromLTWH(0, 0, constraints.maxWidth, style.fontSize! * 1.25);
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$prefix$gap', style: style.copyWith(color: AppCustomColor.textPrimary)),
              TextSpan(
                text: highlight,
                style: style.copyWith(
                  foreground: Paint()..shader = OnboardV2GradientText.headingGradient.createShader(shaderRect),
                ),
              ),
            ],
          ),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.visible,
        );
      },
    );
  }
}
