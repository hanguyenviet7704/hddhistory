part of '../../../../lesson.dart';

/// Multiple-choice option. The Keypoint v2 design draws single- and
/// multiple-choice options identically (including the trailing check/cross
/// chip), so this is a thin alias over [ChoiceAnswerCard] rather than a second
/// copy of the state table.
class MultipleChoiceAnswerCard extends StatelessWidget {
  final OptionEntity option;
  final AnswerState state;
  final VoidCallback? onTap;

  const MultipleChoiceAnswerCard({
    super.key,
    required this.option,
    this.state = AnswerState.normal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceAnswerCard(
      option: option,
      isMultiChoice: true,
      state: state,
      onTap: onTap,
    );
  }
}
