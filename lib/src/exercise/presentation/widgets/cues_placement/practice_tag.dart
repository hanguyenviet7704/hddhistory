part of '../../../exercise.dart';

class CuesPracticeTag extends StatelessWidget {
  const CuesPracticeTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: const Color(0xFFE9556A).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.play_arrow, size: 12, color: Color(0xFFE9556A)),
              ),
              const SizedBox(width: 6),
              const Text(
                'PRACTICE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFE9556A), letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
