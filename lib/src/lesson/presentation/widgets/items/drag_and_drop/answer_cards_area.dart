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
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isDraggingFromSlot ? const Color(0xFFE3E8EF).withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
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
