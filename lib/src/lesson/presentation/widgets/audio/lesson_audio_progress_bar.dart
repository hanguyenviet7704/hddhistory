part of '../../../lesson.dart';

class LessonAudioProgressBar extends StatefulWidget {
  const LessonAudioProgressBar({
    super.key,
    required this.progress,
    this.onSeek,
  });

  /// Current playback fraction in [0, 1].
  final double progress;

  /// Called with the target fraction [0, 1] when the user taps or finishes
  /// dragging (scrubbing) the bar. Null ⇒ a non-interactive display bar.
  final ValueChanged<double>? onSeek;

  @override
  State<LessonAudioProgressBar> createState() => _LessonAudioProgressBarState();
}

class _LessonAudioProgressBarState extends State<LessonAudioProgressBar> {
  // While the user is dragging, show the finger position instead of the
  // (lagging) playback position so the knob tracks the finger smoothly; the
  // actual seek fires on release. Null when not dragging.
  double? _dragFraction;

  double _fractionFromDx(double dx, double width) {
    if (width <= 0) return 0;
    return (dx / width).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onSeek != null;
    final displayProgress = (_dragFraction ?? widget.progress).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final knobCenter = width * displayProgress;
        final knobLeft = knobCenter.clamp(8.w, width - 8.w) - 8.w;

        final bar = Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 8.h,
              decoration: BoxDecoration(
                color: AppCustomColor.borderSecondary,
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            FractionallySizedBox(
              widthFactor: displayProgress,
              child: Container(
                height: 8.h,
                decoration: BoxDecoration(
                  color: AppCustomColor.brandPrimary,
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
            ),
            Positioned(
              left: knobLeft,
              child: Container(
                width: 16.r,
                height: 16.r,
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppCustomColor.brandPrimary,
                    width: 4.w,
                  ),
                ),
              ),
            ),
          ],
        );

        if (!interactive) {
          return SizedBox(height: 16.h, child: bar);
        }

        // Taller transparent hit area (bar is only 8-16.h tall) so the thin bar
        // is comfortable to grab and scrub.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            widget.onSeek!(_fractionFromDx(details.localPosition.dx, width));
          },
          onHorizontalDragStart: (details) {
            setState(() => _dragFraction = _fractionFromDx(details.localPosition.dx, width));
          },
          onHorizontalDragUpdate: (details) {
            setState(() => _dragFraction = _fractionFromDx(details.localPosition.dx, width));
          },
          onHorizontalDragEnd: (_) {
            final fraction = _dragFraction;
            if (fraction != null) widget.onSeek!(fraction);
            setState(() => _dragFraction = null);
          },
          onHorizontalDragCancel: () => setState(() => _dragFraction = null),
          child: SizedBox(
            height: 28.h,
            child: Center(child: SizedBox(height: 16.h, child: bar)),
          ),
        );
      },
    );
  }
}
