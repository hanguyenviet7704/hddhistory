part of '../../../../lesson.dart';

typedef LessonResultOverlayBuilder = Widget Function(BuildContext context);

class LessonResultOverlayManager {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required LessonResultOverlayBuilder builder,
  }) {
    hide();
    final overlay = OverlayEntry(
      builder: (overlayContext) {
        return builder(overlayContext);
      },
    );
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
  static const _overlayAnimationDuration = Duration(milliseconds: 350);

  late final AnimationController _controller = AnimationController(
    duration: _overlayAnimationDuration,
    vsync: this,
  )..forward();

  late final Animation<double> _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slideAnimation =
      Tween<Offset>(
        begin: const Offset(0.0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explanationVisible = widget.showExplanation && widget.explanation != null;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final bottomPadding = math.max(16.h, viewInsets.bottom);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: !explanationVisible,
            child: AnimatedOpacity(
              duration: _overlayAnimationDuration,
              curve: Curves.easeInOut,
              opacity: explanationVisible ? 1 : 0,
              child: GestureDetector(
                onTap: widget.onBackdropTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: AppCustomColor.scrimOverlay,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  bottom: bottomPadding,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: _overlayAnimationDuration,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: explanationVisible
                                ? KeyedSubtree(
                                    key: const ValueKey('lesson-result-overlay-explanation'),
                                    child: widget.explanation!,
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('lesson-result-overlay-empty'),
                                  ),
                          ),
                          widget.summary,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
