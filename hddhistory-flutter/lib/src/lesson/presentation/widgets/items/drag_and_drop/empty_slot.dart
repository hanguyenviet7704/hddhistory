part of '../../../../lesson.dart';

/// An unfilled gap in a text-gap-filling sentence (Keypoint v2 design): a
/// dashed brand-tinted pill sitting inline on the sentence, not the grey box it
/// used to be. Fills with brand tint while a word hovers over it.
class EmptySlot extends StatelessWidget {
  final bool isHighlighted;
  const EmptySlot({super.key, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: isHighlighted ? AppCustomColor.brandPrimary : AppCustomColor.brandPrimary200,
        strokeWidth: isHighlighted ? 2.w : 1.5.w,
        dashPattern: [6.w, 4.w],
        radius: Radius.circular(9.r),
        padding: EdgeInsets.zero,
      ),
      child: Container(
        // A fixed width, NOT `constraints: minWidth`: this Container has no
        // child, and a childless Container takes the largest size its parent
        // allows — inside the sentence `Wrap` that meant every empty gap
        // stretched to the full card width and pushed the prose onto its own
        // lines. `dart analyze` cannot see this; it only shows up on screen.
        width: 96.w,
        height: 30.h,
        decoration: BoxDecoration(
          color: isHighlighted ? AppCustomColor.brandPrimary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(9.r),
        ),
      ),
    );
  }
}
