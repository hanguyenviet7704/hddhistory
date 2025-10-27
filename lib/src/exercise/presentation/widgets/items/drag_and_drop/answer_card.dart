part of '../../../../exercise.dart';

class AnswerCard extends StatelessWidget {
  final String word;
  final bool isDragging;
  final bool isInvisible;

  const AnswerCard({super.key, required this.word, this.isDragging = false, this.isInvisible = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isInvisible ? const Color(0xFFEEF2F6) : Colors.white,
        border: Border.all(color: isInvisible ? const Color(0xFFEEF2F6) : const Color(0xFFE3E8EF), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDragging ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))] : null,
      ),
      child: Text(
        word,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: isInvisible ? Colors.transparent : const Color(0xFF364152), height: 1.5),
      ),
    );
  }
}
