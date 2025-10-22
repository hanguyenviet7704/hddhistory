part of '../../../exercise.dart';

class DraggablePauseMark extends StatelessWidget {
  final int index;
  final VoidCallback onDragEnd;

  const DraggablePauseMark({super.key, required this.index, required this.onDragEnd});

  @override
  Widget build(BuildContext context) {
    return Draggable<Map<String, dynamic>>(
      data: {'action': 'move_existing', 'from_index': index},
      onDragEnd: (details) => onDragEnd(),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: Border.all(color: const Color(0xFF554FF0), width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Center(child: PauseMarkIcon(filled: true)),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E8EF).withOpacity(0.5),
          border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const PauseMarkIcon(filled: false),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const PauseMarkIcon(filled: true),
      ),
    );
  }
}
