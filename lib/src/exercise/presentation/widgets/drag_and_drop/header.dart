part of '../../../exercise.dart';

class DragDropHeader extends StatelessWidget {
  final double progress;
  final VoidCallback onClose;

  const DragDropHeader({super.key, required this.progress, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      height: 40,
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: Color(0xFF7F8EA4), size: 24),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(color: const Color(0xFFE3E8EF), borderRadius: BorderRadius.circular(30)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
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
