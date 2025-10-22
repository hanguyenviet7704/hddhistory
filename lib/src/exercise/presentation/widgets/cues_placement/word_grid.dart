part of '../../../exercise.dart';

class WordGrid extends StatelessWidget {
  final List<dynamic> wordsWithMarks;
  final int? hoveringWordIndex;
  final Function(int, Map<String, dynamic>) onWordAccept;
  final Function(int) onWordHoverChange;
  final VoidCallback onWordHoverExit;
  final VoidCallback onPauseMarkDragEnd;

  const WordGrid({
    super.key,
    required this.wordsWithMarks,
    required this.hoveringWordIndex,
    required this.onWordAccept,
    required this.onWordHoverChange,
    required this.onWordHoverExit,
    required this.onPauseMarkDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: List.generate(wordsWithMarks.length, (index) {
          final item = wordsWithMarks[index];
          final isPauseMark = item is Map && item['type'] == 'pause';
          final isHovering = hoveringWordIndex == index;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPauseMark)
                DraggablePauseMark(index: index, onDragEnd: onPauseMarkDragEnd)
              else
                WordWithDropTarget(word: item, index: index, onAccept: onWordAccept, onHoverChange: onWordHoverChange, onHoverExit: onWordHoverExit),
              if (isHovering && !isPauseMark)
                Container(
                  width: 40,
                  height: 37,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF554FF0).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFF554FF0), width: 2, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: PauseMarkIcon(filled: true)),
                ),
            ],
          );
        }),
      ),
    );
  }
}
