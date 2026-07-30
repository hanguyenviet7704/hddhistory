part of '../../../../lesson.dart';

/// The word bank under a text-gap-filling sentence.
///
/// The Keypoint v2 design drops the grey tray this used to sit in — the chips
/// carry their own border and shadow now, so a tray only boxed them in. The
/// `DragTarget` stays: dropping a chip back here is how a word is pulled out of
/// a gap, and it tints faintly while such a drag is in flight so the target is
/// still discoverable without a permanent frame.
class AnswerCardsArea extends StatelessWidget {
  final List<String> availableWords;
  final Function(String word, int fromIndex) onWordReturnedFromSlot;

  const AnswerCardsArea({
    super.key,
    required this.availableWords,
    required this.onWordReturnedFromSlot,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => details.data['fromIndex'] != null,
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        final word = details.data['word'] as String;
        final fromIndex = details.data['fromIndex'] as int;
        onWordReturnedFromSlot(word, fromIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingFromSlot = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.all(8.w),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isDraggingFromSlot ? AppCustomColor.brandPrimary.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            alignment: WrapAlignment.start,
            children: availableWords.map((word) {
              return Draggable<Map<String, dynamic>>(
                data: {'word': word, 'fromIndex': null},
                // Keeps the card deck out of this gesture — see
                // [KeypointDeckDragLock].
                onDragStarted: KeypointDeckDragLock.begin,
                onDragEnd: (_) => KeypointDeckDragLock.end(),
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.9,
                    child: AnswerCard(word: word, isDragging: true),
                  ),
                ),
                childWhenDragging: AnswerCard(word: word, isInvisible: true),
                child: AnswerCard(word: word),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
