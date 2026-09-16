part of '../../coach.dart';

/// Drawn size of the coach character, in logical px (scaled with `.w` where it
/// is used, like the rest of the app's sizing).
const double kCoachBubbleSize = 60;

/// Gap the shell leaves between the top of the floating nav bar and the bottom
/// of the coach character. Shared with [coachBubbleClearance] so the space the
/// bubble occupies and the space pages reserve for it can never drift apart.
const double kCoachBubbleGap = 12;

/// Vertical space a primary tab must leave below its LAST row, on top of
/// `floatingNavBarHeight(context)`, so the floating coach bubble never sits on
/// top of it.
///
/// Home's "Có ý tưởng?" banner is the row this exists for: it used to end
/// `floatingNavBarHeight + 16` above the screen bottom, which put it squarely
/// under a bubble that starts `+12` up and is 60 tall (design note 2026-09-04:
/// "button góp ý đang bị bubble chat đè lên").
double coachBubbleClearance(BuildContext context) => kCoachBubbleGap.h + kCoachBubbleSize.w + 16.h;

/// The floating Coach — the 60px slime, its badge, and the teaser.
///
/// Sits in the shell's Stack as a sibling of [ImportProgressToast], not inside
/// the popup-host chain. It never opens itself, and because it never does, the
/// Coach stays out of the cold-start scramble between the week-recap poster,
/// the gift popup, the streak toast and the Home promo.
///
/// The character's state follows the door's: a pending plan makes it LEAN
/// toward its own teaser ("Ngóng"), otherwise it just breathes ("Nghỉ") — the
/// design binds each state to a scenario, so the dot and the body language
/// always agree.
class CoachBubble extends StatelessWidget {
  /// Distance from the bottom of the screen. Callers on a primary tab pass
  /// `floatingNavBarHeight(context) + gap` so it clears the nav bar on devices
  /// with a taller inset; sub-routes pass their own safe-area figure.
  final double bottomInset;
  final VoidCallback onTap;
  final bool dot;
  final String? teaser;

  /// Fired once the teaser has finished its single showing.
  ///
  /// The host uses it to stop passing a teaser at all, so the nudge is said
  /// once and then the Coach just sits there — see [_Teaser].
  final VoidCallback? onTeaserDone;

  const CoachBubble({
    super.key,
    required this.bottomInset,
    required this.onTap,
    this.dot = false,
    this.teaser,
    this.onTeaserDone,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 18.w,
      bottom: bottomInset,
      // The teaser sits BESIDE the character, tail pointing at it — the
      // drawing's layout. Stacked above, the tail pointed at nothing.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (teaser != null) ...[
            _Teaser(text: teaser!, onDone: onTeaserDone),
            SizedBox(width: 10.w),
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
                  // No DecoratedBox shadow ring: the body is a morphing blob
                  // now, and a circular shadow behind a non-circle reads as a
                  // halo. The drop shadow travels with the drawing instead.
                  CoachSlime(
                    mood: dot ? CoachSlimeMood.waiting : CoachSlimeMood.idle,
                    size: kCoachBubbleSize,
                    shadow: true,
                  ),
                  // The one dot in the app that means something specific: a
                  // commitment is waiting to be asked about. Anywhere else it
                  // would be decoration, and a decorative dot is how badges
                  // stop being read.
                  if (dot)
                    Positioned(right: -2.w, top: -2.w, child: const _PulseDot()),
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
/// nothing the dot has not already said.
///
/// Said ONCE, for three seconds, and then gone for that screen (owner,
/// 2026-09-16). It used to `repeat()` on a six-second loop: the same sentence
/// fading in and out again every six seconds for as long as the reader stayed
/// on the tab, which does not read as the Coach waiting — it reads as
/// something blinking at you while you are trying to read a course card.
///
/// The keyframe shape is the design's `cv-teaser` and is kept; only the loop
/// and the length changed. [onDone] lets the host drop the teaser entirely
/// afterwards, so it stops taking layout and stops being announced to
/// screen readers.
class _Teaser extends StatefulWidget {
  final String text;
  final VoidCallback? onDone;

  const _Teaser({required this.text, this.onDone});

  @override
  State<_Teaser> createState() => _TeaserState();
}

class _TeaserState extends State<_Teaser> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenCompleteOrCancel(() {
      if (mounted) widget.onDone?.call();
    });
  }

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


/// The badge — the design's `cv-pulse`: a slow 1 → 1.18 breath.
///
/// Pulsing rather than static because the character next to it never stops
/// moving; a frozen dot on a live body reads as a rendering glitch.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.18)
          .chain(CurveTween(curve: Curves.easeInOut))
          .animate(_controller),
      child: Container(
        width: 16.w,
        height: 16.w,
        decoration: BoxDecoration(
          // The design's badge red — warmer than the app's errorRed on
          // purpose: this is an invitation, not an alarm.
          color: const Color(0xFFE4604E),
          shape: BoxShape.circle,
          border: Border.all(color: CoachStyle.surface, width: 3.w),
        ),
      ),
    );
  }
}
