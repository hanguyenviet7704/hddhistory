part of '../../../../../exercise.dart';

class TapBlankSlot extends StatelessWidget {
  final int index;
  final String? placedWord;
  final Function(int index)? onTap;
  final GlobalKey? wordKey;

  const TapBlankSlot({super.key, required this.index, required this.placedWord, this.onTap, this.wordKey});

  @override
  Widget build(BuildContext context) {
    final isFilled = placedWord != null;

    if (isFilled) {
      return GestureDetector(key: wordKey, onTap: onTap != null ? () => onTap!(index) : null, child: _buildFilledSlot(placedWord!));
    }

    return _buildEmptySlot();
  }

  Widget _buildEmptySlot() {
    return CustomPaint(
      painter: DashedBorderPainter(color: const Color(0xFFE3E8EF), strokeWidth: 2, dashWidth: 6, dashSpace: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
        child: Text(
          '',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0), height: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilledSlot(String word) {
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
