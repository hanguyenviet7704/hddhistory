part of '../../../../lesson.dart';

enum LessonTimerDirection {
  countUp,
  countDown,
}

enum LessonTimerStatus {
  idle,
  running,
  paused,
  completed,
}

@immutable
class LessonTimeState {
  const LessonTimeState({
    required this.elapsed,
    required this.total,
    required this.direction,
    required this.status,
  });

  final Duration elapsed;
  final Duration total;
  final LessonTimerDirection direction;
  final LessonTimerStatus status;

  bool get hasTotal => total.inMilliseconds > 0;

  bool get isCompleted => status == LessonTimerStatus.completed;

  Duration get remaining {
    if (!hasTotal) return Duration.zero;
    final int remainingMs = math.max(0, total.inMilliseconds - elapsed.inMilliseconds);
    return Duration(milliseconds: remainingMs);
  }

  Duration get displayDuration => direction == LessonTimerDirection.countDown && hasTotal ? remaining : elapsed;

  double get progress {
    if (!hasTotal) return 0;
    final double ratio = (elapsed.inMilliseconds / total.inMilliseconds).clamp(0, 1).toDouble();
    return direction == LessonTimerDirection.countDown ? 1 - ratio : ratio;
  }

  LessonTimeState copyWith({
    Duration? elapsed,
    Duration? total,
    LessonTimerDirection? direction,
    LessonTimerStatus? status,
  }) {
    return LessonTimeState(
      elapsed: elapsed ?? this.elapsed,
      total: total ?? this.total,
      direction: direction ?? this.direction,
      status: status ?? this.status,
    );
  }
}

class LessonTimeController extends ValueNotifier<LessonTimeState> {
  LessonTimeController({
    Duration? totalDuration,
    Duration initialElapsed = Duration.zero,
    LessonTimerDirection direction = LessonTimerDirection.countUp,
    Duration tick = const Duration(seconds: 1),
    this.onCompleted,
  }) : assert(!tick.isNegative && tick.inMicroseconds > 0, 'tick interval must be positive'),
       _tick = tick,
       super(
         LessonTimeState(
           elapsed: Duration.zero,
           total: totalDuration ?? Duration.zero,
           direction: direction,
           status: LessonTimerStatus.idle,
         ),
       ) {
    if (initialElapsed > Duration.zero) {
      jumpTo(initialElapsed);
    }
  }

  final Duration _tick;
  final VoidCallback? onCompleted;
  Timer? _ticker;

  bool get isRunning => value.status == LessonTimerStatus.running;

  bool get isPaused => value.status == LessonTimerStatus.paused;

  bool get isCompleted => value.isCompleted;

  void start({
    Duration? totalDuration,
    Duration? from,
    LessonTimerDirection? direction,
  }) {
    final Duration resolvedTotal = totalDuration ?? value.total;
    final LessonTimerDirection resolvedDirection = direction ?? value.direction;
    final Duration normalizedElapsed = _normalizeElapsed(from ?? Duration.zero, resolvedTotal);
    final bool shouldCompleteImmediately = resolvedTotal > Duration.zero && normalizedElapsed >= resolvedTotal;

    _stopTicker();
    value = value.copyWith(
      elapsed: shouldCompleteImmediately ? resolvedTotal : normalizedElapsed,
      total: resolvedTotal,
      direction: resolvedDirection,
      status: shouldCompleteImmediately ? LessonTimerStatus.completed : LessonTimerStatus.running,
    );

    if (shouldCompleteImmediately) {
      onCompleted?.call();
      return;
    }

    _ticker = Timer.periodic(_tick, (_) => _tickForward());
  }

  void pause() {
    if (!isRunning) return;
    _stopTicker();
    value = value.copyWith(status: LessonTimerStatus.paused);
  }

  void resume() {
    if (!isPaused || isCompleted) return;
    value = value.copyWith(status: LessonTimerStatus.running);
    _ticker = Timer.periodic(_tick, (_) => _tickForward());
  }

  void reset({bool restart = false}) {
    _stopTicker();
    value = value.copyWith(
      elapsed: Duration.zero,
      status: LessonTimerStatus.idle,
    );
    if (restart) {
      start(direction: value.direction);
    }
  }

  void jumpTo(Duration elapsed) {
    final Duration normalizedElapsed = _normalizeElapsed(elapsed, value.total);
    final bool shouldComplete = value.hasTotal && normalizedElapsed >= value.total;
    value = value.copyWith(
      elapsed: shouldComplete ? value.total : normalizedElapsed,
      status: shouldComplete ? LessonTimerStatus.completed : value.status,
    );

    if (shouldComplete) {
      _stopTicker();
      onCompleted?.call();
    }
  }

  void configure({
    Duration? totalDuration,
    LessonTimerDirection? direction,
  }) {
    if (totalDuration == null && direction == null) return;
    final Duration newTotal = totalDuration ?? value.total;
    final LessonTimerDirection newDirection = direction ?? value.direction;
    final Duration normalizedElapsed = _normalizeElapsed(value.elapsed, newTotal);

    value = value.copyWith(
      total: newTotal,
      direction: newDirection,
      elapsed: normalizedElapsed,
      status: value.status == LessonTimerStatus.completed && normalizedElapsed < newTotal ? LessonTimerStatus.running : value.status,
    );
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  void _tickForward() {
    final Duration total = value.total;
    final Duration nextElapsed = value.elapsed + _tick;
    final bool reachedEnd = value.hasTotal && nextElapsed >= total;

    value = value.copyWith(
      elapsed: reachedEnd ? total : nextElapsed,
      status: reachedEnd ? LessonTimerStatus.completed : LessonTimerStatus.running,
    );

    if (reachedEnd) {
      _stopTicker();
      onCompleted?.call();
    }
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Duration _normalizeElapsed(Duration elapsed, Duration total) {
    if (elapsed.isNegative) return Duration.zero;
    if (total.inMilliseconds <= 0) return elapsed;
    final int clamped = math.min(elapsed.inMilliseconds, total.inMilliseconds);
    return Duration(milliseconds: clamped);
  }
}

class LessonTimeWidget extends StatelessWidget {
  const LessonTimeWidget({
    super.key,
    required this.controller,
    this.size = 24,
    this.gap = 8,
    this.strokeWidth = 3,
    this.textStyle,
    this.textColor = const Color(0xFF554FF0),
    this.progressColor = const Color(0xFF554FF0),
    this.trackColor = const Color(0xFFE3E8EF),
  });

  final LessonTimeController controller;
  final double size;
  final double gap;
  final double strokeWidth;
  final TextStyle? textStyle;
  final Color textColor;
  final Color progressColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LessonTimeState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (!state.hasTotal) return const SizedBox.shrink();

        final double resolvedGap = gap.w;
        final double resolvedSize = size.w;
        final double resolvedStroke = strokeWidth.w;
        final bool isInactive = state.status == LessonTimerStatus.paused || state.status == LessonTimerStatus.idle;
        final Color effectiveTextColor = (textStyle?.color ?? textColor).op(isInactive ? 0.7 : 1);
        final Color effectiveProgressColor = progressColor.op(isInactive ? 0.6 : 1);

        final TextStyle effectiveStyle =
            (textStyle ??
                    TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.75,
                    ))
                .copyWith(color: effectiveTextColor);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              state.displayDuration.formatDuration,
              style: effectiveStyle,
            ),
            SizedBox(width: resolvedGap),
            CircularPercentIndicator(
              radius: resolvedSize / 2,
              lineWidth: resolvedStroke,
              percent: state.progress,
              backgroundColor: trackColor.op(0.5),
              progressColor: effectiveProgressColor,
              circularStrokeCap: CircularStrokeCap.round,
              animateFromLastPercent: true,
              animationDuration: 250,
              startAngle: 270,
            ),
          ],
        );
      },
    );
  }
}

class LessonTimeBanner extends StatefulWidget {
  final VoidCallback? onDone;
  const LessonTimeBanner({super.key, this.onDone});


  @override
  State<LessonTimeBanner> createState() => _LessonTimeBannerState();
}

class _LessonTimeBannerState extends State<LessonTimeBanner> {
  LessonTimeController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  bool _hasQuestionChanged(ExerciseState previous, ExerciseState current) {
    final QuestionEntity prevQuestion = previous.currentQuestion;
    final QuestionEntity currQuestion = current.currentQuestion;
    return prevQuestion.id != currQuestion.id || prevQuestion.completionTime != currQuestion.completionTime;
  }

  LessonTimeController? _buildController(QuestionEntity question) {
    if (question.completionTime <= 0) return null;

    final Duration total = Duration(seconds: question.completionTime);
    final LessonTimeController controller = LessonTimeController(
      totalDuration: total,
      direction: LessonTimerDirection.countDown,
      onCompleted: () => widget.onDone?.call(),
    );

    controller.start(direction: LessonTimerDirection.countDown);
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExerciseCubit, ExerciseState>(
      buildWhen: _hasQuestionChanged,
      builder: (context, state) {
        // Replace controller when question changes so countdown restarts.
        _controller?.dispose();
        _controller = _buildController(state.currentQuestion);

        if (_controller == null) return const SizedBox.shrink();

        final String key = '${state.currentLearningItem.id}-${state.currentQuestion.id}-${state.currentQuestion.completionTime}';

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: LessonTimeWidget(
            key: ValueKey(key),
            controller: _controller!,
          ),
        );
      },
    );
  }
}
