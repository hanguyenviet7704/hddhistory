part of '../../../../lesson.dart';

/// The gapped sentence on a text-gap-filling card.
///
/// The Keypoint v2 design renders it as bare prose on the card — the white
/// bordered panel it used to sit in is gone, since the card is already a panel
/// and the inner frame only shrank the reading width.
class SentenceBuilder extends StatelessWidget {
  final Map<int, String> placedWords;
  final String targetArea;
  final int answerCount;
  final Function(int index, String word, int? fromIndex) onWordPlaced;
  final Function(int index) onWordRemoved;
  final SlotState Function(int index) getSlotState;

  const SentenceBuilder({
    super.key,
    required this.placedWords,
    required this.targetArea,
    required this.answerCount,
    required this.onWordPlaced,
    required this.onWordRemoved,
    required this.getSlotState,
  });

  List<Widget> _buildSentenceWidgets() {
    final widgets = <Widget>[];
    final parts = targetArea.split('___');

    for (int i = 0; i < parts.length; i++) {
      // Add words from this text part, split by space
      if (parts[i].trim().isNotEmpty) {
        final words = parts[i].trim().split(' ');
        for (var word in words) {
          if (word.isNotEmpty) {
            widgets.add(
              AppText(
                word,
                style: AppStyle.text18.copyWith(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w700,
                  color: AppCustomColor.textPrimary,
                  height: 1.3,
                ),
              ),
            );
          }
        }
      }

      // Add blank slot if not the last part
      if (i < answerCount) {
        widgets.add(
          BlankSlot(
            index: i,
            placedWord: placedWords[i],
            onWordPlaced: (word, fromIndex) => onWordPlaced(i, word, fromIndex),
            onWordRemoved: (word, fromIndex) => onWordRemoved(fromIndex),
            onDragCancelled: null,
            slotState: getSlotState(i),
          ),
        );
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6.w,
      // The design's 2.1 line-height on a 19px sentence: enough air for a 34px
      // slot to sit inline without the lines colliding.
      runSpacing: 10.h,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: _buildSentenceWidgets(),
    );
  }
}

/// Model answer shown above the verdict when a gap-filling answer was wrong
/// (Keypoint v2 design). Highlighted-option question types don't need this —
/// their correct choice is already marked in the list — but a sentence has to be
/// restated to be readable.
class GapFillCorrectAnswerPanel extends StatelessWidget {
  const GapFillCorrectAnswerPanel({
    super.key,
    required this.targetArea,
    required this.correctAnswers,
  });

  final String targetArea;
  final List<String> correctAnswers;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppStyle.text14.copyWith(
      fontWeight: FontWeight.w500,
      height: 1.75,
      color: AppCustomColor.kpOptionText,
    );
    final answerStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w800,
      color: AppCustomColor.kpCorrectText,
    );

    final parts = targetArea.split('___');
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i], style: baseStyle));
      if (i < parts.length - 1) {
        final answer = i < correctAnswers.length ? correctAnswers[i] : '';
        spans.add(TextSpan(text: answer, style: answerStyle));
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: AppCustomColor.kpCorrectAnswerSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            context.l10n.exercise.exerciseFeedbackCorrectAnswer,
            margin: EdgeInsets.only(bottom: 6.h),
            style: AppStyle.text12.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppCustomColor.kpCorrectText,
            ),
          ),
          Text.rich(TextSpan(children: spans), maxLines: 20),
        ],
      ),
    );
  }
}
