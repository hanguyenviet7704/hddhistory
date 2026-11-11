part of '../../../lesson.dart';

/// The daily-quota wall as a deck card (design `3 · Learning` → "Keypoint —
/// locked card", markup `_Keypoint Swipe Lab` → `c.isLocked`): the blocked
/// swipe lands HERE instead of bouncing off an invisible wall and getting a
/// paywall thrown over it. Pastel placeholder art and skeleton lines stand for
/// the content a ticket would buy; the overlay says why it is out of reach and
/// sells the one way past ([onGoPremium] → the in-lesson paywall).
///
/// Deliberately inert everywhere else: it names no learning item, carries no
/// narration cue, and files no progress — see `KeypointCardDescriptor.locked`.
class KeypointLockedCard extends StatelessWidget {
  const KeypointLockedCard({super.key, required this.onGoPremium});

  final VoidCallback onGoPremium;

  // Design palette, verbatim. The pastels are this card's own — they stand for
  // unspecified locked content, so they deliberately match no live content
  // token (`brandPrimary` tints them, but none of them IS a brand color).
  static const Color _artGradientStart = Color(0xFFF5ECD5);
  static const Color _artGradientEnd = Color(0xFFFAF6ED);
  static const Color _skeletonTitle = Color(0xFFE4DCC6);
  static const Color _skeletonLine = Color(0xFFE8E2D3);
  static const Color _badgeBackground = Color(0xFFFEF8E9);
  static const Color _bodyText = Color(0xFF5F6F86);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.lesson;

    return SizedBox.expand(
      child: ThemedGlassCard(
        radius: 22,
        frosted: true,
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 18.h),
        shadow: [
          BoxShadow(
            color: AppCustomColor.neutral01.withValues(alpha: 0.06),
            blurRadius: 22.r,
            offset: Offset(0, 8.h),
          ),
        ],
        child: Stack(
          children: [
            // What the wall is standing in front of: a hero block and a few
            // lines of "text" that promise content without leaking any.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _placeholderArt(),
                18.verticalSpace,
                _skeletonBar(widthFactor: 0.46, height: 13.h, color: _skeletonTitle),
                11.verticalSpace,
                _skeletonBar(widthFactor: 0.96, height: 11.h, color: _skeletonLine),
                11.verticalSpace,
                _skeletonBar(widthFactor: 0.88, height: 11.h, color: _skeletonLine),
                11.verticalSpace,
                _skeletonBar(widthFactor: 0.92, height: 11.h, color: _skeletonLine),
                11.verticalSpace,
                _skeletonBar(widthFactor: 0.64, height: 11.h, color: _skeletonLine),
              ],
            ),
            // The wall's own voice, anchored low like the design (its overlay
            // bottom-aligns over the faded content).
            Positioned(
              left: 8.w,
              right: 8.w,
              bottom: 24.h,
              child: Column(
                children: [
                  Container(
                    width: 54.r,
                    height: 54.r,
                    decoration: BoxDecoration(
                      color: _badgeBackground,
                      borderRadius: BorderRadius.circular(17.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.lock_outline_rounded, size: 26.r, color: AppCustomColor.brandPrimary),
                  ),
                  16.verticalSpace,
                  Text(
                    l10n.lockedCardTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      color: AppCustomColor.textPrimary,
                    ),
                  ),
                  8.verticalSpace,
                  Text(
                    l10n.lockedCardBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      color: _bodyText,
                    ),
                  ),
                  20.verticalSpace,
                  Semantics(
                    button: true,
                    label: l10n.lockedCardCta,
                    child: GestureDetector(
                      onTap: onGoPremium,
                      child: Container(
                        height: 48.h,
                        padding: EdgeInsets.symmetric(horizontal: 28.w),
                        decoration: BoxDecoration(
                          color: AppCustomColor.brandPrimary,
                          borderRadius: BorderRadius.circular(99.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.lockedCardCta,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppCustomColor.textWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The design's abstract stand-in for a content image: a soft gradient tile
  /// with two circles and a tilted rounded square drifting out of frame.
  Widget _placeholderArt() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: 200.h,
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_artGradientStart, _artGradientEnd],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -30.w,
                top: -40.h,
                child: _artCircle(190.r, Colors.white.withValues(alpha: 0.7)),
              ),
              Positioned(
                right: -40.w,
                bottom: -60.h,
                child: _artCircle(210.r, AppCustomColor.brandPrimary.withValues(alpha: 0.32)),
              ),
              // Design: left 40% / top 20% of the tile.
              Positioned(
                left: 140.w,
                top: 40.h,
                child: Transform.rotate(
                  angle: 24 * math.pi / 180,
                  child: Container(
                    width: 120.r,
                    height: 120.r,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(38.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _skeletonBar({required double widthFactor, required double height, required Color color}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99.r),
        ),
      ),
    );
  }
}
