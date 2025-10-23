part of '../../../../../exercise.dart';


class TapSentenceBuilder extends StatelessWidget {
  final List<String?> placedWords;
  final Function(int index)? onSlotTap;
  final Map<int, GlobalKey>? wordKeys;

  const TapSentenceBuilder({super.key, required this.placedWords, this.onSlotTap, this.wordKeys});

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
          TapBlankSlot(index: 0, placedWord: placedWords[0], onTap: onSlotTap, wordKey: wordKeys?[0]),
          const Text(
            'of',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0D121C), height: 1.5),
          ),
          TapBlankSlot(index: 1, placedWord: placedWords[1], onTap: onSlotTap, wordKey: wordKeys?[1]),
          const Text(
            'during',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0D121C), height: 1.5),
          ),
          TapBlankSlot(index: 2, placedWord: placedWords[2], onTap: onSlotTap, wordKey: wordKeys?[2]),
          const Text(
            '.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0D121C), height: 1.5),
          ),
        ],
      ),
    );
  }
}
