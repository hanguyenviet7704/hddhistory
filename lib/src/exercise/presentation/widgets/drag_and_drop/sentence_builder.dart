part of '../../../exercise.dart';

class SentenceBuilder extends StatelessWidget {
  final List<String?> placedWords;
  final Function(int index, String word, int? fromIndex) onWordPlaced;
  final Function(String word, int fromIndex) onWordRemoved;
  final Function(String word, int index)? onDragCancelled;

  const SentenceBuilder({super.key, required this.placedWords, required this.onWordPlaced, required this.onWordRemoved, this.onDragCancelled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFE3E8EF).withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 4))],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'A pause is a',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0D121C), height: 1.5),
          ),
          BlankSlot(
            index: 0,
            placedWord: placedWords[0],
            onWordPlaced: (word, fromIndex) => onWordPlaced(0, word, fromIndex),
            onWordRemoved: onWordRemoved,
            onDragCancelled: onDragCancelled,
          ),
          const Text(
            'of',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0D121C), height: 1.5),
          ),
          BlankSlot(
            index: 1,
            placedWord: placedWords[1],
            onWordPlaced: (word, fromIndex) => onWordPlaced(1, word, fromIndex),
            onWordRemoved: onWordRemoved,
            onDragCancelled: onDragCancelled,
          ),
          const Text(
            'during',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0D121C), height: 1.5),
          ),
          BlankSlot(
            index: 2,
            placedWord: placedWords[2],
            onWordPlaced: (word, fromIndex) => onWordPlaced(2, word, fromIndex),
            onWordRemoved: onWordRemoved,
            onDragCancelled: onDragCancelled,
          ),
          const Text(
            '.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0D121C), height: 1.5),
          ),
        ],
      ),
    );
  }
}
