part of '../../../exercise.dart';

class AnswerCardsArea extends StatelessWidget {
  final List<String> availableWords;
  final Function(String word, int fromIndex) onWordReturnedFromSlot;

  const AnswerCardsArea({super.key, required this.availableWords, required this.onWordReturnedFromSlot});

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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDraggingFromSlot ? const Color(0xFF58CC02).withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDraggingFromSlot ? const Color(0xFF58CC02) : const Color(0xFFE3E8EF), width: isDraggingFromSlot ? 3 : 2),
            boxShadow: isDraggingFromSlot
                ? [BoxShadow(color: const Color(0xFF58CC02).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDraggingFromSlot) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_rounded, color: const Color(0xFF58CC02), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Drop here to return',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF58CC02)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              availableWords.isEmpty
                  ? Container(
                      height: 45,
                      alignment: Alignment.center,
                      child: Text(
                        isDraggingFromSlot ? 'Drop here' : 'All words used',
                        style: TextStyle(fontSize: 14, color: const Color(0xFF7F8EA4).withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                      ),
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: availableWords.map((word) {
                        return Draggable<Map<String, dynamic>>(
                          data: {'word': word, 'fromIndex': null},
                          feedback: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(12),
                            child: Opacity(opacity: 0.8, child: AnswerCard(word: word, isDragging: true)),
                          ),
                          childWhenDragging: AnswerCard(word: word, isInvisible: true),
                          // hapticFeedbackOnStart: true,
                          child: AnswerCard(word: word),
                        );
                      }).toList(),
                    ),
            ],
          ),
        );
      },
    );
  }
}
