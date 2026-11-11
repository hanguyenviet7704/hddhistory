part of '../../../../lesson.dart';

/// The gapped sentence on a text-gap-filling card.
///
/// Rendered exactly as the design draws it (`_Keypoint Swipe Lab` → `c.isDnd`):
/// centred 14.5/w600 prose inside a soft lavender panel — the panel is what
/// marks "this is the sentence you are building" apart from the intro copy
/// above it and the word bank below. (An earlier pass removed the panel as
/// redundant chrome and left the sentence as 19px bare prose; side by side with
/// the design that read as a different screen — "trông vẫn khác design lắm",
/// 2026-08-13.)
class SentenceBuilder extends StatelessWidget {
  final Map<int, String> placedWords;
  final String targetArea;
  final int answerCount;
  final Function(int index, String word, int? fromIndex) onWordPlaced;
  final Function(int index) onWordRemoved;
  final SlotState Function(int index) getSlotState;

  /// Tapping a filled gap empties it (see [BlankSlot.onTapFilled]). Null on a
  /// graded card.
  final ValueChanged<int>? onSlotTapped;

  const SentenceBuilder({
    super.key,
    required this.placedWords,
    required this.targetArea,
    required this.answerCount,
    required this.onWordPlaced,
    required this.onWordRemoved,
    required this.getSlotState,
    this.onSlotTapped,
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
                // Design: 14.5/w600, on the panel's own ink.
                style: AppStyle.text14.copyWith(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppCustomColor.textPrimary,
                  height: 1.4,
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
            onTapFilled: onSlotTapped == null ? null : () => onSlotTapped!(i),
          ),
        );
      }
    }

    return widgets;
  }

  /// Design panel: `#FAF9FF` on a `1.5px #E9E6FA` border, radius 18,
  /// padding 16 vertical / 14 horizontal.
  static const Color _kPanelFill = Color(0xFFFFFDF9);
  static const Color _kPanelBorder = Color(0xFFFAF4E6);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _kPanelFill,
        border: Border.all(color: _kPanelBorder, width: 1.5),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Wrap(
        spacing: 6.w,
        // Enough air between runs for an inline slot to sit next to 14.5px text
        // without the lines colliding (design line-height 1.9 does the same job).
        runSpacing: 10.h,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _buildSentenceWidgets(),
      ),
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
