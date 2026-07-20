part of '../../feedback.dart';

class FeedbackRatingRow extends StatelessWidget {
  final String? label;
  final int rating;
  final int maxRating;
  final double starSize;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int>? onRatingChanged;
  final MainAxisAlignment alignment;

  const FeedbackRatingRow({
    super.key,
    this.label,
    required this.rating,
    this.maxRating = 5,
    this.starSize = 24,
    this.spacing = 4,
    this.activeColor = AppCustomColor.feedbackStarActive,
    this.inactiveColor = AppCustomColor.feedbackStarInactive,
    this.onRatingChanged,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final stars = List.generate(maxRating, (index) {
      final starIndex = index + 1;
      final color = starIndex <= rating ? activeColor : inactiveColor;
      return GestureDetector(
        onTap: onRatingChanged == null
            ? null
            : () {
                AppHaptic.select();
                onRatingChanged!(starIndex);
              },
        child: Icon(
          Icons.star_rounded,
          color: color,
          size: starSize.w,
        ),
      );
    });

    final starRow = Row(
      mainAxisAlignment: alignment,
      children: [
        for (var i = 0; i < stars.length; i++) ...[
          stars[i],
          if (i != stars.length - 1) SizedBox(width: spacing.w),
        ],
      ],
    );

    if (label == null) {
      return starRow;
    }

    return Row(
      children: [
        Expanded(
          child: AppText(
            label!,
            style: AppStyle.text14.copyWith(
              fontWeight: FontWeight.w500,
              color: AppCustomColor.textSecondary,
              height: 1.75,
            ),
          ),
        ),
        starRow,
      ],
    );
  }
}
