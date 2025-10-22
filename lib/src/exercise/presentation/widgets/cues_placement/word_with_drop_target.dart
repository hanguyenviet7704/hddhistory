part of '../../../exercise.dart';

class WordWithDropTarget extends StatelessWidget {
  final String word;
  final int index;
  final Function(int, Map<String, dynamic>) onAccept;
  final Function(int) onHoverChange;
  final VoidCallback onHoverExit;

  const WordWithDropTarget({super.key, required this.word, required this.index, required this.onAccept, required this.onHoverChange, required this.onHoverExit});

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (data) {
        if (data.data['action'] == 'place_new') return true;
        if (data.data['action'] == 'move_existing') return true;
        return false;
      },
      onMove: (details) => onHoverChange(index),
      onLeave: (data) => onHoverExit(),
      onAcceptWithDetails: (data) => onAccept(index, data.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return WordCard(word: word, isHovering: isHovering);
      },
    );
  }
}
