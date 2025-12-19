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

class RoleplayExerciseResultBottomSheet extends StatefulWidget {
  final bool isCorrect;
  final VoidCallback onContinue;

  const RoleplayExerciseResultBottomSheet({
    super.key,
    required this.isCorrect,
    required this.onContinue,
  });

  @override
  State<RoleplayExerciseResultBottomSheet> createState() => _RoleplayExerciseResultBottomSheetState();
}

class _RoleplayExerciseResultBottomSheetState extends State<RoleplayExerciseResultBottomSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    final curved = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curved);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(curved);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Translations t = Translations.of(context);

    final String title = widget.isCorrect ? '${t.exercise.exerciseFeedbackCorrectAnswer}!' : t.exercise.exerciseFeedbackIncorrect;

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
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ExerciseResultSummary(
                type: widget.isCorrect ? ResultType.correct : ResultType.incorrect,
                onContinue: widget.onContinue,
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
          ),
        ),
      ],
    );
  }
}
