part of '../../coach.dart';

/// ⑧ — the way out.
///
/// The one screen in this feature allowed to look unlike the rest, and it
/// should: warm ground, a bordered card, its own label colour. Everything stops
/// here — no situation, no columns, no commitment, no course, and nothing at
/// all is written, not even the message that triggered it.
///
/// The design's dashed box at the bottom reads "no situation · no two columns ·
/// no commitment · no course · nothing written". That is an annotation FOR THE
/// PERSON READING THE DRAWING, not copy for someone in crisis — so the slot is
/// kept and filled with what actually belongs there: the numbers to call.
class CoachSafetyPanel extends StatelessWidget {
  final List<CoachHotlineEntity> hotlines;

  const CoachSafetyPanel({super.key, required this.hotlines});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;

    return Container(
      color: CoachStyle.safetyBackground,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.safetyLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08 * 11.sp,
                color: CoachStyle.safetyLabel,
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(17.w),
              decoration: BoxDecoration(
                color: CoachStyle.surface,
                border: Border.all(color: CoachStyle.safetyCardBorder, width: 1.5),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.safetyOpening,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.55,
                      color: CoachStyle.textPrimary,
                    ),
                  ),
                  SizedBox(height: 11.h),
                  Text(
                    l10n.safetyBody,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.65,
                      color: CoachStyle.textBody,
                    ),
                  ),
                  SizedBox(height: 11.h),
                  Text(
                    l10n.safetyDisclaimer,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: CoachStyle.textMuted,
                    ),
                  ),
                  SizedBox(height: 13.h),
                  _HotlineBox(hotlines: hotlines),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The design's dashed slot, carrying the numbers instead of the annotation.
class _HotlineBox extends StatelessWidget {
  final List<CoachHotlineEntity> hotlines;

  const _HotlineBox({required this.hotlines});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;

    return DottedBorderBox(
      color: CoachStyle.safetyDashed,
      radius: 14.r,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.safetyHotlineTitle,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: CoachStyle.safetyStrong,
              ),
            ),
            SizedBox(height: 5.h),
            if (hotlines.isEmpty)
              // An honest empty state. A number that does not work where
              // somebody actually lives is worse than admitting we do not have
              // one for their region.
              Text(
                l10n.safetyNoHotline,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  color: CoachStyle.textMuted,
                ),
              )
            else
              ...hotlines.map(
                (hotline) => Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotline.label,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: CoachStyle.textMuted,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        hotline.number,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: CoachStyle.safetyStrong,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A dashed rounded rectangle.
///
/// Hand-painted rather than pulled in as a package: it is one border in one
/// place, and the design draws it at a specific dash rhythm.
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;

  const DottedBorderBox({
    super.key,
    required this.child,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = dartui.Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    const dash = 4.0;
    const gap = 3.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}
