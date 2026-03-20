part of '../../../roleplay.dart';

class RoleplayFeedbackStrengthIndicator extends StatelessWidget {
  final StrengthLevel level;

  const RoleplayFeedbackStrengthIndicator({super.key, required this.level});

  Color get _activeColor {
    return switch (level) {
      StrengthLevel.weakPoint => AppCustomColor.errorRed,
      StrengthLevel.morePractice => AppCustomColor.brandPrimary,
      StrengthLevel.optionalPractice => AppCustomColor.successGreen,
      StrengthLevel.unknown => AppCustomColor.borderSecondary,
    };
  }

  int get _activeBars {
    return switch (level) {
      StrengthLevel.weakPoint => 3,
      StrengthLevel.morePractice => 2,
      StrengthLevel.optionalPractice => 1,
      StrengthLevel.unknown => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<double> barHeights = [8.h, 13.h, 18.h];
    return SizedBox(
      width: 24.w,
      height: 24.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barHeights.length, (index) {
          final bool isActive = index < _activeBars;
          return Container(
            width: 4.w,
            height: barHeights[index],
            decoration: BoxDecoration(
              color: isActive ? _activeColor : AppCustomColor.borderSecondary,
              borderRadius: BorderRadius.circular(100.r),
            ),
          );
        }),
      ),
    );
  }
}
