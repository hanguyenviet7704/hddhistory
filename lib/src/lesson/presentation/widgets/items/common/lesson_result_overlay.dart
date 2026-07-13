part of '../../../../lesson.dart';

typedef LessonResultOverlayBuilder = Widget Function(BuildContext context);

class LessonResultOverlayManager {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required LessonResultOverlayBuilder builder,
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

class LessonResultOverlay extends StatefulWidget {
  final Widget summary;
  final Widget? explanation;
  final bool showExplanation;
  final VoidCallback? onBackdropTap;

  const LessonResultOverlay({
    super.key,
    required this.summary,
    this.explanation,
    this.showExplanation = false,
    this.onBackdropTap,
  });

  @override
  State<LessonResultOverlay> createState() => _LessonResultOverlayState();
}

class _LessonResultOverlayState extends State<LessonResultOverlay> with SingleTickerProviderStateMixin {
  static final Duration _panelAnimationDuration = 380.ms;
  static final Duration _scrimAnimationDuration = 280.ms;

  late final AnimationController _panelController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(vsync: this, duration: _panelAnimationDuration)..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _panelController,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _panelController, curve: Curves.easeOutQuart),
        );
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1).animate(
      CurvedAnimation(parent: _panelController, curve: Curves.easeOutQuart),
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explanationVisible = widget.showExplanation && widget.explanation != null;

    final panelContent = ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.explanation != null)
            AnimatedCrossFade(
              duration: _panelAnimationDuration,
              reverseDuration: _panelAnimationDuration,
              sizeCurve: Curves.easeOutQuart,
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeOut,
              crossFadeState: explanationVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: widget.explanation!,
              secondChild: const SizedBox.shrink(),
              layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(key: bottomChildKey, child: bottomChild),
                    Positioned(key: topChildKey, child: topChild),
                  ],
                );
              },
            ),
          widget.summary,
        ],
      ),
    );

    final animatedPanel = FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: panelContent,
        ),
      ),
    );

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Always-present modal barrier while a result is shown — this overlay
        // lives in the ROOT overlay, above the lesson content, so without a
        // full-screen hit-testable barrier here, scrolling/tapping the reading
        // content behind the summary card still works right through it. Only
        // the darkened scrim's VISIBILITY is conditional on the explanation
        // panel being expanded; the touch-blocking itself never was.
        Positioned.fill(
          child: GestureDetector(
            onTap: explanationVisible ? widget.onBackdropTap : null,
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              duration: _scrimAnimationDuration,
              curve: Curves.easeOut,
              opacity: explanationVisible ? 1 : 0,
              child: Container(color: AppCustomColor.scrimOverlay),
            ),
          ),
        ),
        animatedPanel,
      ],
    );
  }
}
