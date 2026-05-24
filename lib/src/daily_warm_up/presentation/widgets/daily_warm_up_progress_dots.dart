part of '../../daily_warm_up.dart';

class DailyWarmUpProgressDots extends StatelessWidget {
  const DailyWarmUpProgressDots({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final safeCount = math.max(0, count);
    if (safeCount == 0) return const SizedBox.shrink();

    final gap = safeCount > 6 ? 4.w : 6.w;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(safeCount, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: active ? 18.w : 8.w,
          height: 8.w,
          margin: EdgeInsets.symmetric(horizontal: gap / 2),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF4B44CA) : const Color(0xFFE3E8EF),
            borderRadius: BorderRadius.circular(999.r),
          ),
        );
      }),
    );
  }
}
