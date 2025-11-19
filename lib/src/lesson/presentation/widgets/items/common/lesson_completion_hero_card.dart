part of '../../../../lesson.dart';

class LessonCompletionHeroCard extends StatelessWidget {
  const LessonCompletionHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = 227.w;
    final double height = 95.h;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 46.w,
            right: 10.w,
            bottom: -6.h,
            child: Container(
              height: 24.h,
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary50.op(0.6),
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          Positioned(
            left: 36.w,
            right: 0,
            top: 4.h,
            bottom: 16.h,
            child: Container(
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          Positioned(
            left: 48.w,
            right: 16.w,
            top: 20.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8.h,
              children: [
                _buildLine(width: 68.w, opacity: 1),
                _buildLine(width: 120.w, opacity: 0.4),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 14.h,
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          Positioned(
            left: -4.w,
            top: -4.h,
            child: Icon(
              Icons.auto_awesome,
              size: 14.sp,
              color: AppCustomColor.brandPrimary200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine({required double width, required double opacity}) {
    return Container(
      width: width,
      height: 12.h,
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary100.op(opacity),
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }
}
