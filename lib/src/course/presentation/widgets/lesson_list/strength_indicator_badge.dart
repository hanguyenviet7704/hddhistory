part of '../../../course.dart';

class StrengthIndicatorBadge extends StatelessWidget {
  final StrengthLevel level;

  const StrengthIndicatorBadge({
    super.key,
    required this.level,
  });

  Color get _getBarColor {
    return switch (level) {
      StrengthLevel.weakPoint => AppCustomColor.errorRed,
      StrengthLevel.morePractice => AppCustomColor.brandPrimary,
      StrengthLevel.optionalPractice => AppCustomColor.successGreen
    };
  }

  int get _getBarCount {
    return switch (level) {
      StrengthLevel.weakPoint => 3,
      StrengthLevel.morePractice => 2,
      StrengthLevel.optionalPractice => 1
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16.w,
      height: 16.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bar 1 (shortest)
          Container(
            width: 2.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: _getBarCount >= 1 ? _getBarColor : AppCustomColor.textBrand.op(0.16),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
          2.horizontalSpace,
          // Bar 2 (medium)
          Container(
            width: 2.w,
            height: 7.h,
            decoration: BoxDecoration(
              color: _getBarCount >= 2 ? _getBarColor : AppCustomColor.textBrand.op(0.16),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
          2.horizontalSpace,
          // Bar 3 (tallest)
          Container(
            width: 2.w,
            height: 10.h,
            decoration: BoxDecoration(
              color: _getBarCount >= 3 ? _getBarColor : AppCustomColor.textBrand.op(0.16),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
        ],
      ),
    );
  }
}
