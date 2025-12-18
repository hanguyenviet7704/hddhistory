part of '../../../../roleplay.dart';

typedef RoleplayExerciseOverlayBuilder = Widget Function(BuildContext context);

class RoleplayExerciseOverlayManager {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required RoleplayExerciseOverlayBuilder builder,
    required VoidCallback onOverlayShown,
  }) {
    hide();
    final overlay = OverlayEntry(builder: builder);
    Overlay.of(context, rootOverlay: true).insert(overlay);
    _currentEntry = overlay;
    onOverlayShown();
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static bool get isVisible => _currentEntry != null;
}

class RoleplayExerciseOverlayInteractive extends StatefulWidget {
  final QuestionEntity exercise;
  final VoidCallback onCheckPressed;

  const RoleplayExerciseOverlayInteractive({
    super.key,
    required this.exercise,
    required this.onCheckPressed,
  });

  @override
  State<RoleplayExerciseOverlayInteractive> createState() => _RoleplayExerciseOverlayInteractiveState();
}

class _RoleplayExerciseOverlayInteractiveState extends State<RoleplayExerciseOverlayInteractive> {
  bool _isExpanded = false;

  void _expand() {
    if (_isExpanded) return;
    setState(() => _isExpanded = true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: AppDI.injector.get<ExerciseCubit>()),
        BlocProvider.value(value: AppDI.injector.get<ChoiceCubit>()),
        BlocProvider.value(value: AppDI.injector.get<DragAndDropCubit>()),
        BlocProvider.value(value: AppDI.injector.get<ArrangeTheSequenceCubit>()),
        BlocProvider.value(value: AppDI.injector.get<CuesPlacementCubit>()),
        BlocProvider.value(value: AppDI.injector.get<MarkStressWordCubit>()),
        BlocProvider.value(value: AppDI.injector.get<SpeakingCubit>()),
        // BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
        // BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
      ],
      child: RoleplayExerciseOverlay(
        exercise: widget.exercise,
        isExpanded: _isExpanded,
        onTapToAnswer: _expand,
        onCheckPressed: widget.onCheckPressed,
      ),
    );
  }
}

class RoleplayExerciseOverlay extends StatelessWidget {
  final QuestionEntity exercise;
  final bool isExpanded;
  final VoidCallback? onTapToAnswer;
  final VoidCallback? onCheckPressed;

  const RoleplayExerciseOverlay({
    super.key,
    required this.exercise,
    this.isExpanded = false,
    this.onTapToAnswer,
    this.onCheckPressed,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.paddingOf(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(bottom: viewPadding.bottom > 0 ? viewPadding.bottom / 4 : 8.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.op(0.08),
              offset: const Offset(0, -4),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          // minimum: EdgeInsets.only(bottom: viewPadding.bottom > 0 ? viewPadding.bottom / 2 : 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DragHandle(),
              if (isExpanded)
                _ExpandedExerciseBody(
                  exercise: exercise,
                  onCheckPressed: onCheckPressed,
                )
              else
                _CollapsedExerciseBody(
                  questionText: exercise.questionText,
                  onTapToAnswer: onTapToAnswer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 24.w, 0),
      child: Center(
        child: Container(
          width: 48.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppCustomColor.borderSecondary,
            borderRadius: BorderRadius.circular(30.r),
          ),
        ),
      ),
    );
  }
}
