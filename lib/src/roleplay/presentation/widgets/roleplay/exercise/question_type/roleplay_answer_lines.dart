part of '../../../../../roleplay.dart';

class RoleplayAnswerLines extends StatelessWidget {
  final List<String> items;
  final TextStyle style;
  final int maxLines;

  const RoleplayAnswerLines({
    super.key,
    required this.items,
    required this.style,
    this.maxLines = 10,
  });

  @override
  Widget build(BuildContext context) {
    final lines = items.where((e) => e.isNotEmpty).toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    return AppText(
      lines.join('\n'),
      maxLines: maxLines,
      overflow: TextOverflow.visible,
      style: style,
    );
  }
}
