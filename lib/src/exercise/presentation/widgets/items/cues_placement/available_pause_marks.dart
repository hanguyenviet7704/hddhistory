part of '../../../../exercise.dart';

class AvailablePauseMarks extends StatelessWidget {
  final int totalMarks;
  final int availableMarks;
  final Function(Map<String, dynamic>) onAccept;
  final VoidCallback onHover;
  final VoidCallback onDragEnd;

  const AvailablePauseMarks({super.key, required this.totalMarks, required this.availableMarks, required this.onAccept, required this.onHover, required this.onDragEnd});

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (data) => data.data['action'] == 'move_existing',
      onMove: (details) => onHover(),
      onAcceptWithDetails: (data) => onAccept(data.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: isHovering ? BoxDecoration(color: const Color(0xFF554FF0).op(0.1), borderRadius: BorderRadius.circular(12)) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalMarks, (index) {
              final hasMarkAvailable = index < availableMarks;

              if (hasMarkAvailable) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Draggable<Map<String, dynamic>>(
                    data: {'action': 'place_new'},
                    onDragEnd: (details) => onDragEnd(),
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.op(0.9),
                          border: Border.all(color: const Color(0xFF554FF0), width: 2),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.op(0.2), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Center(child: PauseMarkIcon(filled: true)),
                      ),
                    ),
                    childWhenDragging: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E8EF),
                        border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: PauseMarkIcon(filled: false)),
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: PauseMarkIcon(filled: true)),
                    ),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E8EF),
                      border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: PauseMarkIcon(filled: false)),
                  ),
                );
              }
            }),
          ),
        );
      },
    );
  }
}
