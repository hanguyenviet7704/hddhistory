part of '../../../video_lesson.dart';

const _videoLessonFastAnimationDuration = Duration(milliseconds: 180);
const _videoLessonMediumAnimationDuration = Duration(milliseconds: 240);
const _videoLessonEntranceCurve = Curves.easeOutCubic;
const _videoLessonSpringCurve = Curves.easeOutBack;
const _videoLessonExitCurve = Curves.easeInCubic;

class _VideoLessonAnimatedEntrance extends StatefulWidget {
  const _VideoLessonAnimatedEntrance({
    required this.child,
    this.beginOffset = Offset.zero,
    this.beginScale = 0.96,
    this.duration = _videoLessonMediumAnimationDuration,
    this.delay = Duration.zero,
    this.curve = _videoLessonEntranceCurve,
  });

  final Widget child;
  final Offset beginOffset;
  final double beginScale;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  @override
  State<_VideoLessonAnimatedEntrance> createState() => _VideoLessonAnimatedEntranceState();
}

class _VideoLessonAnimatedEntranceState extends State<_VideoLessonAnimatedEntrance> {
  Timer? _timer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _scheduleEntrance();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleEntrance() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.delay == Duration.zero) {
        setState(() => _isVisible = true);
        return;
      }

      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _isVisible = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _isVisible ? 1 : 0),
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
      builder: (context, value, child) {
        final opacity = _clampUnitInterval(value);
        final dx = lerpDouble(widget.beginOffset.dx, 0, value) ?? 0;
        final dy = lerpDouble(widget.beginOffset.dy, 0, value) ?? 0;
        final scale = lerpDouble(widget.beginScale, 1, value) ?? 1;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

double _clampUnitInterval(double value) => value.clamp(0.0, 1.0).toDouble();

class _VideoLessonAnimatedVisibility extends StatelessWidget {
  const _VideoLessonAnimatedVisibility({
    required this.visible,
    required this.child,
    this.hiddenOffset = const Offset(0, 0.08),
  });

  final bool visible;
  final Widget child;
  final Offset hiddenOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: _videoLessonFastAnimationDuration,
      curve: visible ? _videoLessonEntranceCurve : _videoLessonExitCurve,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: _videoLessonFastAnimationDuration,
        curve: visible ? _videoLessonEntranceCurve : _videoLessonExitCurve,
        offset: visible ? Offset.zero : hiddenOffset,
        child: child,
      ),
    );
  }
}

class _VideoLessonPressableScale extends StatefulWidget {
  const _VideoLessonPressableScale({
    required this.child,
    this.onTap,
    this.behavior = HitTestBehavior.deferToChild,
  });

  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;

  @override
  State<_VideoLessonPressableScale> createState() => _VideoLessonPressableScaleState();
}

class _VideoLessonPressableScaleState extends State<_VideoLessonPressableScale> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    if (onTap == null) return widget.child;

    return GestureDetector(
      behavior: widget.behavior,
      onTap: onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: _videoLessonEntranceCurve,
        scale: _isPressed ? 0.97 : 1,
        child: widget.child,
      ),
    );
  }
}
