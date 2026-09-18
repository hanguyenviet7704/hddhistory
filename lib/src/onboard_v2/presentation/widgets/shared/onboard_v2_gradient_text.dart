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

  /// Dải màu thương hiệu 5 chặng — dùng cho VIỀN (thẻ lựa chọn, thẻ thông báo)
  /// và cũng là dải của hình minh hoạ S9. Không phải dải của tiêu đề.
  static const gradient = LinearGradient(
    colors: [
      Color(0xFF4B44CA),
      Color(0xFFA052FF),
      Color(0xFFEF81D4),
      Color(0xFFFF8F8F),
      Color(0xFFFFCE66),
    ],
  );

  /// Dải màu của MỌI tiêu đề onboarding trong Claude Design: `100deg`, ba chặng
  /// #5B4FE8 → #C56BD6 (52%) → #F4A45C. Góc 100° gần ngang, chếch xuống một
  /// chút, nên hai đầu lệch trục dọc 0,18.
  static const headingGradient = LinearGradient(
    begin: Alignment(-1, -0.18),
    end: Alignment(1, 0.18),
    colors: [Color(0xFF5B4FE8), Color(0xFFC56BD6), Color(0xFFF4A45C)],
    stops: [0, 0.52, 1],
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => headingGradient.createShader(Offset.zero & bounds.size),
      child: AppText(
        text,
        textAlign: textAlign,
        overflow: TextOverflow.visible,
        style: style ?? AppStyle.text28.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
