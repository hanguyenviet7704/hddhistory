part of '../../../exercise.dart';

class BlankSlot extends StatelessWidget {
  final int index;
  final String? placedWord;
  final Function(String word, int? fromIndex) onWordPlaced;
  final Function(String word, int fromIndex) onWordRemoved;
  final Function(String word, int index)? onDragCancelled;

  const BlankSlot({super.key, required this.index, required this.placedWord, required this.onWordPlaced, required this.onWordRemoved, this.onDragCancelled});

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
              borderRadius: BorderRadius.circular(8),
              child: Opacity(opacity: 0.8, child: _buildFilledSlot(word, isDragging: true)),
            ),
            childWhenDragging: _buildEmptySlot(isHighlighted: true),
            onDragCompleted: () {},
            onDraggableCanceled: (velocity, offset) {
              if (onDragCancelled != null) {
                onDragCancelled!(word, index);
              }
            },
            // hapticFeedbackOnStart: true,
            child: _buildFilledSlot(word),
          );
        }

        return _buildEmptySlot(isHighlighted: candidateData.isNotEmpty);
      },
    );
  }

  Widget _buildEmptySlot({bool isHighlighted = false}) {
    return CustomPaint(
      painter: DashedBorderPainter(color: isHighlighted ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF), strokeWidth: 2, dashWidth: 6, dashSpace: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(color: isHighlighted ? const Color(0xFF554FF0).withValues(alpha: 0.08) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
        child: Text(
          '',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0), height: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilledSlot(String word, {bool isDragging = false}) {
    return CustomPaint(
      painter: DashedBorderPainter(color: const Color(0xFF554FF0), strokeWidth: 2, dashWidth: 6, dashSpace: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFF554FF0).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(
          word,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF554FF0), height: 1.5),
        ),
      ),
    );
  }
}
