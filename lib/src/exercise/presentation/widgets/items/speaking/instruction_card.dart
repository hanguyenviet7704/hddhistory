part of '../../../../exercise.dart';

class InstructionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onPlayAudio;

  const InstructionCard({super.key, required this.title, required this.subtitle, this.onPlayAudio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.op(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF58CC02).op(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.mic_rounded, color: Color(0xFF58CC02), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 16, color: Color(0xFF5D7285))),
              ],
            ),
          ),
          if (onPlayAudio != null)
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF1CB0F6)),
              onPressed: onPlayAudio,
            ),
        ],
      ),
    );
  }
}
