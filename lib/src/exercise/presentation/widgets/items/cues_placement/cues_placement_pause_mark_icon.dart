part of '../../../../exercise.dart';

/// Pause mark icon widget - two vertical bars representing pause (II symbol)
class CuesPlacementPauseMarkIcon extends StatelessWidget {
  final bool filled;

  const CuesPlacementPauseMarkIcon({
    super.key,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24.w,
      height: 24.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // First bar
            Container(
              width: 2.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: filled ? const Color(0xFF554FF0) : Colors.transparent,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            4.horizontalSpace,
            // Second bar
            Container(
              width: 2.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: filled ? const Color(0xFF554FF0) : Colors.transparent,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
