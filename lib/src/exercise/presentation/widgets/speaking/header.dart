part of '../../../exercise.dart';

class SpeakingHeader extends StatelessWidget {
  final VoidCallback onBack;
  final double progress;

  const SpeakingHeader({super.key, required this.onBack, this.progress = 0.6});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: onBack,
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE0E6ED),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF58CC02)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.favorite_border, color: Colors.red, size: 28),
      ],
    );
  }
}
