part of '../../../../../exercise.dart';

class PauseMarkIcon extends StatelessWidget {
  final bool filled;

  const PauseMarkIcon({super.key, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 2,
            height: 12,
            decoration: BoxDecoration(color: filled ? const Color(0xFF554FF0) : Colors.transparent, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 4),
          Container(
            width: 2,
            height: 12,
            decoration: BoxDecoration(color: filled ? const Color(0xFF554FF0) : Colors.transparent, borderRadius: BorderRadius.circular(3)),
          ),
        ],
      ),
    );
  }
}
