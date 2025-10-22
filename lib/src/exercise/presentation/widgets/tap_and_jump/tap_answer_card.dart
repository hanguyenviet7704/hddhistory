part of '../../../exercise.dart';

class TapAnswerCard extends StatelessWidget {
  final String word;
  final bool isDisabled;
  final VoidCallback? onTap;

  const TapAnswerCard({super.key, required this.word, this.isDisabled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFFEEF2F6) : Colors.white,
          border: Border.all(color: isDisabled ? const Color(0xFFEEF2F6) : const Color(0xFFE3E8EF), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          word,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: isDisabled ? const Color(0xFF7F8EA4).withValues(alpha: 0.4) : const Color(0xFF364152), height: 1.5),
        ),
      ),
    );
  }
}
