part of '../../../../lesson.dart';

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
          padding: EdgeInsets.all(12.w),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            // Light-grey tray (was white): the answer chips are white, so a
            // white tray made them blend together ("dính nhau") and its empty
            // right area read as a cut-off empty chip. A grey fill + padding
            // makes each white chip stand out and keeps them off the edges.
            color: isDraggingFromSlot ? const Color(0xFFE3E8EF) : const Color(0xFFF0F3F9),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            alignment: WrapAlignment.start,
            children: availableWords.map((word) {
              return Draggable<Map<String, dynamic>>(
                data: {'word': word, 'fromIndex': null},
                feedback: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Opacity(
                    opacity: 0.8,
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
