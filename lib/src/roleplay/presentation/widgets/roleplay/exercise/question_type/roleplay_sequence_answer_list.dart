part of '../../../../../roleplay.dart';

class RoleplaySequenceAnswerList extends StatelessWidget {
  final List<String> items;
  final TextStyle style;

  const RoleplaySequenceAnswerList({
    super.key,
    required this.items,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final lines = items.where((e) => e.isNotEmpty).toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.map((entry) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 21.w,
              child: AppText(
                '${entry.key + 1}.',
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: style,
              ),
            ),
            Expanded(
              child: AppText(
                entry.value,
                maxLines: 6,
                overflow: TextOverflow.visible,
                style: style,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
