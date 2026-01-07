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

class _RoleplayExerciseOverlayInteractiveState extends State<RoleplayExerciseOverlayInteractive> with SingleTickerProviderStateMixin {
  static const double _dragThreshold = 18;
  static const double _velocityThreshold = 500;

  bool _isExpanded = false;
  bool _showResult = false;
  bool _isCorrect = false;
  double _dragDistance = 0;
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
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(curved);
    _animationController.forward();
  }

  void _expand() {
    _setExpanded(true);
  }

  void _collapse() {
    _setExpanded(false);
  }

  void _setExpanded(bool value) {
    if (_isExpanded == value) return;
    setState(() => _isExpanded = value);
  }

  void _handleDragStart(DragStartDetails details) {
    _dragDistance = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.delta.dy;
    if (_dragDistance <= -_dragThreshold) {
      _expand();
      _dragDistance = 0;
      return;
    }
    if (_dragDistance >= _dragThreshold) {
      _collapse();
      _dragDistance = 0;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_velocityThreshold) {
      _expand();
    } else if (velocity >= _velocityThreshold) {
      _collapse();
    }
    _dragDistance = 0;
  }

  void _handleAnswerChecked(bool isCorrect) {
    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
      _isExpanded = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
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
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RoleplayExerciseOverlay(
            exercise: widget.exercise,
            isExpanded: _isExpanded,
            showResult: _showResult,
            isCorrect: _isCorrect,
            onTapToAnswer: _expand,
            onCheckPressed: widget.onCheckPressed,
            onAnswerChecked: _handleAnswerChecked,
            onTapOutside: _collapse,
            onDragStart: _handleDragStart,
            onDragUpdate: _handleDragUpdate,
            onDragEnd: _handleDragEnd,
          ),
        ),
      ),
    );
  }
}

class RoleplayExerciseOverlay extends StatelessWidget {
  final QuestionEntity exercise;
  final bool isExpanded;
  final bool showResult;
  final bool isCorrect;
  final VoidCallback? onTapToAnswer;
  final VoidCallback? onCheckPressed;
  final ValueChanged<bool>? onAnswerChecked;
  final VoidCallback? onTapOutside;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  const RoleplayExerciseOverlay({
    super.key,
    required this.exercise,
    this.isExpanded = false,
    this.showResult = false,
    this.isCorrect = false,
    this.onTapToAnswer,
    this.onCheckPressed,
    this.onAnswerChecked,
    this.onTapOutside,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.paddingOf(context);
    final double maxOverlayHeight = MediaQuery.sizeOf(context).height * 0.75;
    final double maxBodyHeight = (maxOverlayHeight - _dragHandleHeight() - viewPadding.bottom).clamp(0.0, maxOverlayHeight);
    final Widget collapsedBody = _CollapsedExerciseBody(
      questionText: exercise.questionText,
      onTapToAnswer: onTapToAnswer,
    );
    final Widget expandedBody = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxBodyHeight),
      child: _ExpandedExerciseBody(
        exercise: exercise,
        onAnswerChecked: onAnswerChecked,
        showResult: showResult,
        isCorrect: isCorrect,
        onContinue: onCheckPressed,
      ),
    );
    final bool isForcedExpanded = showResult || isExpanded;

    return Stack(
      children: [
        if (isExpanded && !showResult)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTapOutside,
              child: const SizedBox.expand(),
            ),
          ),
        Align(
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
                  _DragHandle(
                    onDragStart: showResult ? null : onDragStart,
                    onDragUpdate: showResult ? null : onDragUpdate,
                    onDragEnd: showResult ? null : onDragEnd,
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 240),
                    firstCurve: Curves.easeOutCubic,
                    secondCurve: Curves.easeInCubic,
                    sizeCurve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    crossFadeState: isForcedExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: collapsedBody,
                    secondChild: expandedBody,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  const _DragHandle({
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: onDragStart,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      child: SizedBox(
        height: 20.h,
        width: double.infinity,
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 24.w, 0),
          alignment: Alignment.topCenter,
          child: Container(
            width: 48.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppCustomColor.borderSecondary,
              borderRadius: BorderRadius.circular(30.r),
            ),
          ),
        ),
      ),
    );
  }
}

double _dragHandleHeight() => 12.h + 4.h;
