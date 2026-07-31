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
      _ => AppCustomColor.kpOptionText,
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
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                option.value.text,
                maxLines: 10,
                style: AppStyle.text14.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            if (trailing != null) ...[
              12.horizontalSpace,
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
