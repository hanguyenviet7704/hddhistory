part of '../../../../lesson.dart';

/// Bottom half of a keypoint exercise card (Keypoint v2 design): the
/// "Check answer" pill while the question is open, and — once it has been
/// graded — the result banner plus explanation IN PLACE of that pill.
///
/// The old flow pushed a `ResultBottomSheet` over the whole screen with its own
/// Continue button. In the swipe deck the design keeps the verdict inside the
/// card and hands advancing back to the swipe gesture (see
/// [KeypointCardShell]), so nothing covers the answers the reader just picked.
///
/// Exercise types the v2 design does not cover (cues placement, stress
/// placement, speaking) keep the sticky bottom button + result sheet; only the
/// four designed types render this.
class KeypointExerciseAction extends StatelessWidget {
  const KeypointExerciseAction({
    super.key,
    required this.hasChecked,
    required this.isCorrect,
    this.canCheck = false,
    this.onCheck,
    this.explanationText,
    this.correctAnswer,
  });

  final bool hasChecked;
  final bool isCorrect;

  /// Whether enough of an answer is present for grading to be meaningful — the
  /// pill stays visibly inert (not merely a no-op) until it is.
  final bool canCheck;
  final VoidCallback? onCheck;

  final String? explanationText;

  /// Model answer shown above the verdict when the reader got it wrong, for
  /// question types where the correct response is a sentence rather than a
  /// highlighted option (gap filling).
  final Widget? correctAnswer;

  /// Reports the same "reader has seen their result" event the result sheet
  /// used to fire when it opened. The verdict is now part of the card, so the
  /// grading transition is the moment it becomes visible.
  static void trackResultViewed() {
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackKeypointExerciseResultView(trackingData);
  }

  /// Counterpart to [trackResultViewed] for leaving a graded card. Called by
  /// [KeypointCardShell] when the swipe that used to be the sheet's Continue
  /// button lands.
  static void trackContinue() {
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackKeypointExerciseContinue(trackingData);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasChecked) {
      return Padding(
        padding: EdgeInsets.only(top: 18.h),
        child: KeypointCheckAnswerButton(
          isEnabled: canCheck,
          onPressed: onCheck,
        ),
      );
    }

    final explanation = explanationText ?? '';

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCorrect && correctAnswer != null) correctAnswer!,
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isCorrect ? AppCustomColor.kpResultCorrectSurface : AppCustomColor.kpWrongSurface,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  isCorrect ? context.l10n.exercise.exerciseInlineResultCorrect : context.l10n.exercise.exerciseFeedbackIncorrectTitle,
                  style: AppStyle.text14.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: isCorrect ? AppCustomColor.kpCorrectText : AppCustomColor.kpWrongText,
                  ),
                ),
                if (explanation.isNotEmpty)
                  AppText(
                    explanation,
                    margin: EdgeInsets.only(top: 10.h),
                    maxLines: 100,
                    style: AppStyle.text14.copyWith(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      color: AppCustomColor.kpOptionText,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The design's Check-answer control: a centered pill sized to its label, not
/// the screen-wide bar the sticky bottom action uses. Disabled state keeps the
/// brand hue at low saturation instead of going grey, so it still reads as
/// "the next thing to press".
class KeypointCheckAnswerButton extends StatelessWidget {
  const KeypointCheckAnswerButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.lesson.checkAnswerButton;

    return Center(
      child: Semantics(
        button: true,
        enabled: isEnabled,
        // No explicit label: the child text already provides one, and setting
        // both makes VoiceOver read it twice.
        child: Material(
          color: isEnabled ? AppCustomColor.brandPrimary : AppCustomColor.kpCheckDisabled,
          borderRadius: BorderRadius.circular(999.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(999.r),
            onTap: isEnabled && onPressed != null
                ? () {
                    AppHaptic.select();
                    onPressed!();
                  }
                : null,
            // No `alignment` on this Container: an alignment turns it into an
            // Align, which expands to the incoming width instead of hugging its
            // label — the pill stretched across the whole card. A min-width Row
            // centres the label while still letting the box shrink-wrap.
            child: Container(
              constraints: BoxConstraints(minWidth: 168.w),
              height: 46.h,
              padding: EdgeInsets.symmetric(horizontal: 26.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    label,
                    style: AppStyle.text14.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppCustomColor.textWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The one-line "how to answer this" hint under an exercise question.
///
/// The design tints it per exercise type — violet for the pick-one shapes,
/// green for the pick-many / ordering shapes — so a reader swiping through a
/// deck can tell what kind of question they landed on before reading a word.
class KeypointExerciseInstruction extends StatelessWidget {
  const KeypointExerciseInstruction({
    super.key,
    required this.text,
    required this.accent,
  });

  final String text;
  final KeypointExerciseAccent accent;

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      margin: EdgeInsets.only(bottom: 14.h),
      maxLines: 3,
      style: AppStyle.text13.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: accent == KeypointExerciseAccent.violet ? AppCustomColor.kpAccentViolet : AppCustomColor.kpAccentGreen,
      ),
    );
  }
}

enum KeypointExerciseAccent { violet, green }

/// Trailing check / cross chip on a graded answer option. [muted] is the
/// design's third variant: a correct option the reader did NOT pick, marked so
/// they can see what they missed without it reading as their own success.
class KeypointOptionBadge extends StatelessWidget {
  const KeypointOptionBadge({
    super.key,
    required this.isCorrect,
    this.muted = false,
  });

  final bool isCorrect;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final background = muted
        ? AppCustomColor.kpMissedBadge
        : isCorrect
        ? AppCustomColor.kpCorrectBorder
        : AppCustomColor.kpWrongBorder;

    return Container(
      width: 21.w,
      height: 21.w,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6.r),
      ),
      alignment: Alignment.center,
      child: Icon(
        isCorrect ? Icons.check_rounded : Icons.close_rounded,
        size: 14.sp,
        color: AppCustomColor.textWhite,
      ),
    );
  }
}
