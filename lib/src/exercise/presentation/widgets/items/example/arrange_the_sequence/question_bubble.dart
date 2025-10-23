part of '../../../../../exercise.dart';

class QuestionBubble extends StatelessWidget {
  final String question;
  final String? avatarUrl;

  const QuestionBubble({super.key, required this.question, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: const Color(0xFFE3E8EF), borderRadius: BorderRadius.circular(44)),
          child: avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('🦉', style: TextStyle(fontSize: 24)));
                    },
                  ),
                )
              : const Center(child: Text('🦉', style: TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question,
              style: const TextStyle(color: Color(0xFF0D121C), fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
