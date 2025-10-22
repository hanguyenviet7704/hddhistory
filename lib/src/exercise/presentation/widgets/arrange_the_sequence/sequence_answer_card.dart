part of '../../../exercise.dart';

class SequenceAnswerCard extends StatelessWidget {
  final String text;
  final int index;

  const SequenceAnswerCard({super.key, required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ReorderableDragStartListener(
          index: index,
          child: Row(
            children: [
              const Icon(Icons.menu, color: Color(0xFF7F8EA4), size: 24),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(color: Color(0xFF364152), fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
