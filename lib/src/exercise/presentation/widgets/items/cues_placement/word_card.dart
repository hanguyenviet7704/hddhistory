part of '../../../../exercise.dart';

class WordCard extends StatelessWidget {
  final String word;
  final bool isHovering;

  const WordCard({super.key, required this.word, this.isHovering = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: isHovering ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF), width: isHovering ? 3 : 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(word, style: const TextStyle(fontSize: 14, color: Color(0xFF364152), height: 1.75)),
    );
  }
}
