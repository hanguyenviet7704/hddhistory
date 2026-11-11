part of '../../output_practice.dart';

class OutputPracticeThinkingRow extends StatelessWidget {
  const OutputPracticeThinkingRow({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.label,
  });

  final String name;
  final String avatarUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OutputPracticeAvatar(url: avatarUrl),
          8.horizontalSpace,
          AppText(
            label,
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.textTertiary,
              fontStyle: FontStyle.italic,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }
}
