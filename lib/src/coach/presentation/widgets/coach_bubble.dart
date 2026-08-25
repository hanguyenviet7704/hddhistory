part of '../../coach.dart';

/// The floating Coach bubble — 60px, the skin colour, and a face.
///
/// Sits in the shell's Stack as a sibling of [ImportProgressToast], not inside
/// the popup-host chain. It never opens itself, and because it never does, the
/// Coach stays out of the cold-start scramble between the week-recap poster,
/// the gift popup, the streak toast and the Home promo.
class CoachBubble extends StatelessWidget {
  /// Distance from the bottom of the screen. Callers on a primary tab pass
  /// `floatingNavBarHeight(context) + gap` so it clears the nav bar on devices
  /// with a taller inset; sub-routes pass their own safe-area figure.
  final double bottomInset;
  final VoidCallback onTap;
  final bool dot;
  final String? teaser;

  const CoachBubble({
    super.key,
    required this.bottomInset,
    required this.onTap,
    this.dot = false,
    this.teaser,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 18.w,
      bottom: bottomInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (teaser != null) ...[
            _Teaser(text: teaser!),
            SizedBox(height: 10.h),
          ],
          Semantics(
            button: true,
            label: context.l10n.coach.bubbleSemantics,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99.r),
                      boxShadow: CoachStyle.bubbleShadow,
                    ),
                    child: const CoachFace.bubble(),
                  ),
                  // The one dot in the app that means something specific: a
                  // commitment is waiting to be asked about. Anywhere else it
                  // would be decoration, and a decorative dot is how badges
                  // stop being read.
                  if (dot)
                    Positioned(
                      right: 1.w,
                      top: 1.w,
                      child: Container(
                        width: 13.w,
                        height: 13.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF04438),
                          shape: BoxShape.circle,
                          border: Border.all(color: CoachStyle.surface, width: 2.w),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The reader's own commitment, quoted back in one line.
///
/// Their words, not "you have something waiting" — a generic teaser tells them
/// nothing the dot has not already said. It breathes on a slow loop so it reads
/// as the Coach waiting rather than as a banner.
class _Teaser extends StatefulWidget {
  final String text;

  const _Teaser({required this.text});

  @override
  State<_Teaser> createState() => _TeaserState();
}

class _TeaserState extends State<_Teaser> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 0 → fade in, hold, → fade out. The design's `cv-teaser` keyframes:
        // in by 10%, out from 72%.
        final t = _controller.value;
        final opacity = t < 0.1
            ? t / 0.1
            : t < 0.72
            ? 1.0
            : 1 - (t - 0.72) / 0.28;
        final slide = (1 - opacity) * 10;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(slide.w, 0), child: child),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: 220.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: CoachStyle.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(16.r),
            bottomRight: Radius.circular(5.r),
          ),
          boxShadow: CoachStyle.teaserShadow,
        ),
        child: Text(
          widget.text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            height: 1.45,
            color: CoachStyle.textPrimary,
          ),
        ),
      ),
    );
  }
}
