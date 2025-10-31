part of '../../../../lesson.dart';

class BlankSlot extends StatelessWidget {
  final int index;
  final String? placedWord;
  final Function(String word, int? fromIndex) onWordPlaced;
  final Function(String word, int fromIndex) onWordRemoved;
  final Function(String word, int index)? onDragCancelled;
  final SlotState slotState;

  const BlankSlot({
    super.key,
    required this.index,
    required this.placedWord,
    required this.onWordPlaced,
    required this.onWordRemoved,
    this.onDragCancelled,
    this.slotState = SlotState.normal,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = placedWord != null;

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => !isFilled,
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        final draggedWord = details.data['word'] as String;
        final fromIndex = details.data['fromIndex'] as int?;
        onWordPlaced(draggedWord, fromIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final word = placedWord;
        if (isFilled && word != null) {
          return Draggable<Map<String, dynamic>>(
            data: {'word': word, 'fromIndex': index},
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8.r),
              child: Opacity(
                opacity: 0.8,
                child: FilledSlot(word: word, isDragging: true, state: slotState),
              ),
            ),
            childWhenDragging: EmptySlot(isHighlighted: true),
            onDragCompleted: () {},
            onDraggableCanceled: (velocity, offset) {
              if (onDragCancelled != null) {
                onDragCancelled!(word, index);
              }
            },
            child: FilledSlot(word: word, state: slotState),
          );
        }

        return EmptySlot(isHighlighted: candidateData.isNotEmpty);
      },
    );
  }
}
