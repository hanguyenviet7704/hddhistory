part of '../../../../lesson.dart';

/// A gap that already holds a word. Keeps the dashed outline of [EmptySlot] so
/// the sentence still reads as fill-in-the-blank after every gap is filled, and
/// switches to the graded palette once the answer has been checked.
class FilledSlot extends StatelessWidget {
  final String word;
  final bool isDragging;
  final SlotState state;

  const FilledSlot({
    super.key,
    required this.word,
    this.isDragging = false,
    this.state = SlotState.normal,
  });

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: _borderColor,
        strokeWidth: 1.5.w,
        dashPattern: [6.w, 4.w],
        radius: Radius.circular(9.r),
        padding: EdgeInsets.zero,
      ),
      // Deliberately no `alignment` — see the note in
      // [KeypointCheckAnswerButton]: it would make this expand to the sentence's
      // full width instead of hugging the word.
      child: Container(
        constraints: BoxConstraints(minWidth: 96.w),
        height: 34.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              word,
              style: AppStyle.text14.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                height: 1,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _borderColor {
    return switch (state) {
      SlotState.correct => AppCustomColor.kpCorrectBorder,
      SlotState.incorrect => AppCustomColor.kpWrongBorder,
      SlotState.normal => AppCustomColor.kpAccentViolet,
    };
  }

  Color get _backgroundColor {
    return switch (state) {
      SlotState.correct => AppCustomColor.kpCorrectSurface,
      SlotState.incorrect => AppCustomColor.kpWrongSurface,
      SlotState.normal => AppCustomColor.kpGapFilledSurface,
    };
  }

  Color get _textColor {
    return switch (state) {
      SlotState.correct => AppCustomColor.kpCorrectText,
      SlotState.incorrect => AppCustomColor.kpWrongText,
      SlotState.normal => AppCustomColor.streakActive,
    };
  }
}
