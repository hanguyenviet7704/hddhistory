part of '../../../../../roleplay.dart';

class RoleplayGapFillingAnswer extends StatelessWidget {
  final String template;
  final List<String> answers;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const RoleplayGapFillingAnswer({
    super.key,
    required this.template,
    required this.answers,
    required this.baseStyle,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (template.isEmpty) return const SizedBox.shrink();

    final parts = template.split('___');
    final spans = <InlineSpan>[];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        spans.add(TextSpan(text: part, style: baseStyle));
      }

      if (i < answers.length) {
        final answer = answers[i].replaceAll('"', '').replaceAll('“', '').replaceAll('”', '').trim();
        spans.add(TextSpan(text: answer, style: highlightStyle));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
