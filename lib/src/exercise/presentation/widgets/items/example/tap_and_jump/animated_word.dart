part of '../../../../../exercise.dart';

class AnimatedWord extends StatelessWidget {
  final String word;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;

  const AnimatedWord({super.key, required this.word, required this.startPosition, required this.endPosition, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: startPosition, end: endPosition),
      duration: 400.ms,
      curve: Curves.easeInOut,
      onEnd: onComplete,
      builder: (context, offset, child) {
        return Positioned(left: offset.dx, top: offset.dy, child: child!);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF554FF0).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF554FF0), width: 2),
        ),
        child: Text(
          word,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF554FF0), height: 1.5),
        ),
      ).animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 200.ms),
    );
  }
}
