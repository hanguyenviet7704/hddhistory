part of '../../../../../exercise.dart';

class DragPracticeTag extends StatelessWidget {
  const DragPracticeTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: const Color(0xFFE9556A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: const Icon(Icons.square, color: Color(0xFFE9556A), size: 15),
        ),
        const SizedBox(width: 6),
        const Text(
          'PRACTICE',
          style: TextStyle(color: Color(0xFFE9556A), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
      ],
    );
  }
}
