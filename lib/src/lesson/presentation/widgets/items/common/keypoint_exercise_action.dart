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
/// ONE colour for every exercise type — brand violet, 12.5/600, exactly as the
/// design draws it on all four question shapes (`_Keypoint Swipe Lab`). It used
/// to tint green for the pick-many / ordering shapes on the theory that the hue
/// told a swiping reader what kind of question they had landed on; the design
/// does not do that, and the hint says the same thing in words directly above the
/// options anyway.
class KeypointExerciseInstruction extends StatelessWidget {
  const KeypointExerciseInstruction({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      margin: EdgeInsets.only(bottom: 10.h),
      maxLines: 3,
      style: AppStyle.text13.copyWith(
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppCustomColor.brandPrimary,
      ),
    );
  }
}

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

    // The design's own glyph, drawn as SVG rather than composed from Material
    // icons: `check_rounded` and `close_rounded` sit on different optical grids
    // and neither matches the tick's long tail. 18px box, corner radius scaled
    // from the design's rx:7 on a 24 viewBox.
    final fill = _hex(background);
    final mark = isCorrect
        ? '<path d="M6.375 11.7384L10.2955 15.75L17.625 8.25" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'
        : '<path d="M15.3295 16L7.99998 8.5" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M8.32953 16L15.6591 8.5" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>';

    return SvgPicture.string(
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="7" fill="$fill"/>$mark</svg>',
      width: 18.w,
      height: 18.w,
    );
  }

  static String _hex(Color color) => '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
