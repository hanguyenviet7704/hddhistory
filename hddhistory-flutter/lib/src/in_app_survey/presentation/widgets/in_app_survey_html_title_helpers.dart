part of '../../in_app_survey.dart';

double? _readPxValue(String inlineStyle, String property) {
  final match = RegExp('$property\\s*:\\s*([0-9.]+)px', caseSensitive: false).firstMatch(inlineStyle);
  return match == null ? null : double.tryParse(match.group(1) ?? '');
}

FontWeight? _readFontWeight(String inlineStyle) {
  final match = RegExp(r'font-weight\s*:\s*([0-9]+|bold|normal)', caseSensitive: false).firstMatch(inlineStyle);
  final value = match?.group(1)?.toLowerCase();
  if (value == null) return null;
  final weight = value == 'normal' ? 400 : (value == 'bold' ? 700 : int.tryParse(value));
  return switch (weight) {
    null => null,
    >= 900 => FontWeight.w900,
    >= 800 => FontWeight.w800,
    >= 700 => FontWeight.w700,
    >= 600 => FontWeight.w600,
    >= 500 => FontWeight.w500,
    >= 400 => FontWeight.w400,
    >= 300 => FontWeight.w300,
    >= 200 => FontWeight.w200,
    _ => FontWeight.w100,
  };
}

Color? _readHexColor(String inlineStyle, String property) {
  final match = RegExp('$property\\s*:\\s*#([0-9a-f]{6}|[0-9a-f]{8})', caseSensitive: false).firstMatch(inlineStyle);
  final value = match?.group(1);
  if (value == null) return null;
  return Color(int.parse(value.length == 6 ? 'FF$value' : value, radix: 16));
}

class _GradientTitleText extends StatelessWidget {
  const _GradientTitleText({
    required this.text,
    required this.style,
    required this.gradient,
  });

  final String text;
  final TextStyle style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
