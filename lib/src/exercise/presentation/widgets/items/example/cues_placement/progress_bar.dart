part of '../../../../../exercise.dart';

class CuesProgressBar extends StatelessWidget {
  final VoidCallback onClose;
  final double progress;

  const CuesProgressBar({super.key, required this.onClose, this.progress = 0.3});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Icon(Icons.close, size: 20, color: Color(0xFF7F8EA4)),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(color: const Color(0xFFE3E8EF), borderRadius: BorderRadius.circular(30)),
              child: FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFF0D121C), borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
