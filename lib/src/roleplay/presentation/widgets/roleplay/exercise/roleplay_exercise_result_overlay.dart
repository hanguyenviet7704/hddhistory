part of '../../../../roleplay.dart';

typedef RoleplayExerciseResultOverlayBuilder = Widget Function(BuildContext context);

class RoleplayExerciseResultOverlayManager {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required RoleplayExerciseResultOverlayBuilder builder,
  }) {
    hide();
    final overlay = OverlayEntry(builder: builder);
    Overlay.of(context, rootOverlay: true).insert(overlay);
    _currentEntry = overlay;
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static bool get isVisible => _currentEntry != null;
}

class RoleplayExerciseResultBottomSheet extends StatelessWidget {
  final bool isCorrect;
  final VoidCallback onContinue;

  const RoleplayExerciseResultBottomSheet({
    super.key,
    required this.isCorrect,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final Translations t = Translations.of(context);

    final String title = isCorrect ? '${t.exercise.exerciseFeedbackCorrectAnswer}!' : t.exercise.exerciseFeedbackIncorrect;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        const Positioned.fill(
          child: ModalBarrier(
            dismissible: false,
            color: Colors.transparent,
          ),
        ),
        SafeArea(
          top: false,
          child: ExerciseResultSummary(
            type: isCorrect ? ResultType.correct : ResultType.incorrect,
            onContinue: onContinue,
            continueLabel: t.exercise.exerciseSkipButton,
            explainLabel: '',
            closeExplainLabel: '',
            title: title,
            successAccentColor: AppCustomColor.successGreen,
            errorAccentColor: AppCustomColor.errorRed,
            successBackgroundColor: AppCustomColor.backgroundSuccess,
            errorBackgroundColor: AppCustomColor.backgroundError,
          ),
        ),
      ],
    );
  }
}
