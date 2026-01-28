part of '../../feedback.dart';

class FeedbackReasonList extends StatelessWidget {
  final Map<IncompleteFeedbackReason, String> labels;
  final List<IncompleteFeedbackReason> selected;
  final ValueChanged<IncompleteFeedbackReason> onToggle;

  const FeedbackReasonList({
    super.key,
    required this.labels,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: labels.entries.map((entry) {
        return FeedbackReasonChip(
          label: entry.value,
          isSelected: selected.contains(entry.key),
          onTap: () => onToggle(entry.key),
        );
      }).toList(),
    );
  }
}
