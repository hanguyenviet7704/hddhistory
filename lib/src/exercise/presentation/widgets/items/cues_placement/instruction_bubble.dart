part of '../../../../exercise.dart';

class InstructionBubble extends StatelessWidget {
  final String instruction;

  const InstructionBubble({super.key, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Avatar(),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -10,
                top: 20,
                child: CustomPaint(
                  size: const Size(20, 16),
                  painter: BubbleTailPainter(color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
                ),
                child: Text(
                  instruction,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0D121C), height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
