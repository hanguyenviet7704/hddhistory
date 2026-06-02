part of '../../../../lesson.dart';

class AnswerCardsArea extends StatelessWidget {
  final List<String> availableWords;
  final List<String> allWords;
  final Function(String word, int fromIndex) onWordReturnedFromSlot;

  const AnswerCardsArea({
    super.key,
    required this.availableWords,
    required this.allWords,
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDraggingFromSlot ? const Color(0xFFE3E8EF).withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            alignment: WrapAlignment.center,
            // runAlignment: WrapAlignment.center,
            // crossAxisAlignment: WrapCrossAlignment.center,
            children: allWords.map((word) {
              final isAvailable = availableWords.contains(word);

              if (isAvailable) {
                // Word is available - show as draggable card
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
              } else {
                // Word is placed in a slot - show as drop target placeholder
                return DragTarget<Map<String, dynamic>>(
                  onWillAcceptWithDetails: (details) {
                    final draggedWord = details.data['word'] as String;
                    final fromIndex = details.data['fromIndex'] as int?;
                    return draggedWord == word && fromIndex != null;
                  },
                  onAcceptWithDetails: (details) {
                    HapticFeedback.mediumImpact();
                    final fromIndex = details.data['fromIndex'] as int;
                    onWordReturnedFromSlot(word, fromIndex);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: isHovering
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF58CC02).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: AnswerCard(word: word, isInvisible: true),
                    );
                  },
                );
              }
            }).toList(),
          ),
        );
      },
    );
  }
}
