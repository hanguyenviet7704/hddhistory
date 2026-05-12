part of '../../../onboard_v2.dart';

class OnboardV2GradientText extends StatelessWidget {
  const OnboardV2GradientText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  static const gradient = LinearGradient(
    colors: [
      Color(0xFF4B44CA),
      Color(0xFFA052FF),
      Color(0xFFEF81D4),
      Color(0xFFFF8F8F),
      Color(0xFFFFCE66),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size),
      child: AppText(
        text,
        textAlign: textAlign,
        overflow: TextOverflow.visible,
        style: style ?? AppStyle.text28.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
