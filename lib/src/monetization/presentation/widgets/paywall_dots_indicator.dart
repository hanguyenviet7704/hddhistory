part of '../../monetization.dart';

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color activeColor;
  final Color color;

  const _DotsIndicator({required this.count, required this.activeIndex, required this.activeColor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: isActive ? 16.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: isActive ? activeColor : color,
            borderRadius: BorderRadius.circular(50.r),
          ),
        );
      }),
    );
  }
}
