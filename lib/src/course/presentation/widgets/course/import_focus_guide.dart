part of '../../../course.dart';

/// Shown once, ever: what the button beside the search field is for.
const String _kImportGuideSeenKey = 'learning_import.explore_guide_seen';

/// The coach mark that introduces Import on Explore.
///
/// A spotlight rather than a tooltip because the affordance it explains is a
/// bare icon: an upload glyph next to a search field reads as "attach something"
/// to roughly nobody, and the feature behind it — turn a video or a PDF into a
/// lesson — is the kind of thing a reader has to be told exists once. After that
/// the icon is enough.
///
/// Lives in [CoursePage]'s stack, above the whole tab, and reads the button's
/// real rect off [_importButtonKey] rather than guessing at coordinates: the
/// button's position moves with the safe area, and a hole cut in the wrong place
/// highlights the notch.
///
/// **Marked seen on the tap that dismisses it, not on show.** Explore can push
/// the auto-open paywall over this on a first run, and a guide that spent its one
/// showing while covered by another screen would never be seen at all.
class ImportFocusGuide extends StatefulWidget {
  const ImportFocusGuide({super.key});

  @override
  State<ImportFocusGuide> createState() => _ImportFocusGuideState();
}

class _ImportFocusGuideState extends State<ImportFocusGuide> {
  /// Long enough for the tab transition to settle — a scrim that fades in
  /// mid-push reads as a rendering fault rather than as a deliberate step.
  static const Duration _kSettleDelay = Duration(milliseconds: 600);

  /// The button's rect, resolved once the first frame exists. Null = nothing to
  /// point at, so nothing is drawn.
  Rect? _target;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    _settleTimer = Timer(_kSettleDelay, () => unawaited(_maybeShow()));
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybeShow() async {
    if (!mounted) return;

    final store = AppDI.injector.get<ILocalStoreService>();
    if (await store.getBool(key: _kImportGuideSeenKey)) return;
    if (!mounted) return;

    // Something else is on top (the auto-open paywall, a deep link). Leave the
    // flag unspent and let the next visit to Explore do this.
    if (ModalRoute.of(context)?.isCurrent != true) return;

    final target = _resolveTargetRect();
    if (target == null) return;

    setState(() => _target = target);
  }

  /// Where the import button actually is, in this widget's own coordinates.
  Rect? _resolveTargetRect() {
    final buttonContext = _importButtonKey.currentContext;
    final selfBox = context.findRenderObject();
    if (buttonContext == null || selfBox is! RenderBox) return null;

    final buttonBox = buttonContext.findRenderObject();
    if (buttonBox is! RenderBox || !buttonBox.hasSize) return null;

    final topLeft = buttonBox.localToGlobal(Offset.zero, ancestor: selfBox);

    // Inflated so the ring sits around the button instead of on it — the design
    // cuts a 66pt hole around a 50pt control.
    return (topLeft & buttonBox.size).inflate(5.w);
  }

  Future<void> _dismiss() async {
    AppHaptic.select();
    setState(() => _target = null);
    await AppDI.injector.get<ILocalStoreService>().setBool(
      key: _kImportGuideSeenKey,
      value: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    if (target == null) return const SizedBox.shrink();

    final l10n = context.l10n.learningImport;

    return Positioned.fill(
      child: Semantics(
        container: true,
        button: true,
        label: '${l10n.guideBody} ${l10n.guideHint}',
        child: GestureDetector(
          onTap: () => unawaited(_dismiss()),
          behavior: HitTestBehavior.opaque,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            builder: (context, value, child) =>
                Opacity(opacity: value, child: child),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      hole: target,
                      radius: 22.r,
                      unit: 1.w,
                    ),
                  ),
                ),
                Positioned(
                  left: 24.w,
                  right: 76.w,
                  top: target.bottom + 42.h,
                  child: _GuideCard(body: l10n.guideBody, hint: l10n.guideHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark ground with a hole in it, and the arrow that points through.
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.unit,
  });

  final Rect hole;
  final double radius;

  /// One design pixel in logical pixels, so the arrow scales with the rest of
  /// the UI instead of shrinking on a large phone.
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = RRect.fromRectAndRadius(hole, Radius.circular(radius));
    final bounds = Offset.zero & size;

    // Punched with a layer + BlendMode.clear rather than a combined path:
    // `Path` here would resolve to retrofit's annotation of the same name, which
    // this library imports unprefixed.
    canvas
      ..saveLayer(bounds, Paint())
      ..drawRect(bounds, Paint()..color = const Color(0xDB090C14))
      ..drawRRect(ring, Paint()..blendMode = BlendMode.clear)
      ..restore();

    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * unit
        ..color = Colors.white,
    );

    _paintArrow(canvas);
  }

  /// An elbow from beside the card up into the hole: rises on the hole's centre
  /// line, then turns left toward the text. Offsets are the design's, measured
  /// from the bottom edge of the hole.
  void _paintArrow(Canvas canvas) {
    final centerX = hole.center.dx;
    final top = hole.bottom + 6.5 * unit;
    final bottom = hole.bottom + 93 * unit;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFFCC6F);

    final head = hole.bottom + 17 * unit;

    // Four segments instead of one path, for the same reason the scrim is
    // punched rather than combined — `Path` is taken in this library. Round caps
    // make the elbow and the tip read as joins.
    canvas
      ..drawLine(Offset(centerX - 25 * unit, bottom), Offset(centerX, bottom), paint)
      ..drawLine(Offset(centerX, bottom), Offset(centerX, top), paint)
      ..drawLine(Offset(centerX - 8 * unit, head), Offset(centerX, top), paint)
      ..drawLine(Offset(centerX + 8 * unit, head), Offset(centerX, top), paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole ||
      oldDelegate.radius != radius ||
      oldDelegate.unit != unit;
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.body, required this.hint});

  final String body;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0x660D121C),
            blurRadius: 40.r,
            offset: Offset(0, 16.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            body,
            style: AppStyle.text16.copyWith(
              fontSize: 15.sp,
              height: 1.45,
              color: AppCustomColor.textPrimary,
            ),
            maxLines: 4,
          ),
          12.verticalSpace,
          AppText(
            hint,
            style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
