part of '../../../../lesson.dart';

/// One answer option on a single- or multiple-choice card (Keypoint v2 design).
///
/// Five visual states, all driven by [AnswerState] — the design's grading pass
/// distinguishes "you picked it and were right", "you picked it and were wrong",
/// "this was right and you missed it" and "wrong, and you left it alone", so a
/// reader can read the whole outcome off the list without opening anything.
class ChoiceAnswerCard extends StatelessWidget {
  final OptionEntity option;
  final bool isMultiChoice;
  final AnswerState state;
  final VoidCallback? onTap;

  const ChoiceAnswerCard({
    super.key,
    required this.option,
    this.isMultiChoice = false,
    this.state = AnswerState.normal,
    this.onTap,
  });

  Color get backgroundColor {
    return switch (state) {
      AnswerState.correct => AppCustomColor.kpCorrectSurface,
      AnswerState.incorrect => AppCustomColor.kpWrongSurface,
      AnswerState.correctNotSelected => AppCustomColor.kpMissedSurface,
      // A picked option is TINTED, not just outlined (design). The 2px brand
      // border alone had to carry the whole "this is my answer" signal on a row
      // barely taller than its text.
      AnswerState.selected => AppCustomColor.kpOptionSelectedSurface,
      _ => AppCustomColor.backgroundWhite,
    };
  }

  Color get borderColor {
    return switch (state) {
      AnswerState.selected => AppCustomColor.brandPrimary,
      AnswerState.correct => AppCustomColor.kpCorrectBorder,
      AnswerState.incorrect => AppCustomColor.kpWrongBorder,
      AnswerState.correctNotSelected => AppCustomColor.kpMissedBorder,
      // Left alone and wrong: recedes rather than competing with the verdict.
      AnswerState.disabled => AppCustomColor.kpDimBorder,
      _ => AppCustomColor.kpOptionBorder,
    };
  }

  /// The design thickens the border only once an option carries meaning —
  /// selected, or graded.
  double get borderWidth {
    return switch (state) {
      AnswerState.selected => 2,
      AnswerState.correct => 2,
      AnswerState.incorrect => 2,
      AnswerState.correctNotSelected => 2,
      _ => 1.5,
    };
  }

  Color get textColor {
    return switch (state) {
      AnswerState.disabled => AppCustomColor.kpDimText,
      AnswerState.selected => AppCustomColor.kpOptionSelectedText,
      _ => AppCustomColor.kpOptionLabel,
    };
  }

  Widget? get badge {
    return switch (state) {
      AnswerState.correct => const KeypointOptionBadge(isCorrect: true),
      AnswerState.incorrect => const KeypointOptionBadge(isCorrect: false),
      AnswerState.correctNotSelected => const KeypointOptionBadge(isCorrect: true, muted: true),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final trailing = badge;

    return GestureDetector(
      onTap: state == AnswerState.disabled ? null : onTap,
      child: Container(
        alignment: Alignment.centerLeft,
        // Design geometry: 13/10 padding in a 13 radius, with a shadow so soft it
        // reads as lift rather than as a second border. The card was 15/14 in a 16
        // radius, which cost a whole option's worth of height on a four-option
        // question — the reason the Check pill could end up under the fold.
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(13.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF252525).withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                option.value.text,
                maxLines: 10,
                style: AppStyle.text14.copyWith(
                  fontSize: 13.5.sp,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
            if (trailing != null) ...[
              10.horizontalSpace,
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
