part of '../../coach.dart';

/// The Coach's seven states, each bound to a place in the flow — the design's
/// "Trạng thái ↔ scenario" table, not decoration:
///
/// | state   | where                                             |
/// |---------|---------------------------------------------------|
/// | idle    | Home, nothing pending — breathes, looks around     |
/// | waiting | ③A a plan is waiting — leans toward the teaser     |
/// | listen  | the reader is telling — flattens, eyes wide        |
/// | think   | asking back / two columns / composing — tall, tilts |
/// | cheer   | closing praise, mood-end — hops, eyes curve shut   |
/// | gentle  | ⑧ safety, low mood — sags, slows right down        |
/// | sleep   | a reminder gone dormant — near-still, eyes lines   |
enum CoachSlimeMood { idle, waiting, listen, think, cheer, gentle, sleep }

/// Which state the sheet's avatar shows for the step the session is parked at.
///
/// Mirrors the drawing's own selector: safety wins over everything, composing
/// reads as thinking, the free-text steps read as listening, and the closing
/// steps get the one small celebration this character is allowed.
CoachSlimeMood coachSlimeMoodFor({
  required String step,
  required bool typing,
  required bool safety,
}) {
  if (safety) return CoachSlimeMood.gentle;
  if (typing) return CoachSlimeMood.think;

  switch (step) {
    // Nhịp 2–3: "cao và hẹp lại, nghiêng đầu, mắt ngước lên".
    case 'twoCols':
    case 'redraft':
    case 'shrink':
    // Luồng 4 — choosing the habit, weighing the retry.
    case 'scenePick':
    case 'sceneFix':
    // Luồng 5 — the check-in question, the offer, the quiz.
    case 'checkinAsk':
    case 'checkinOffer':
    case 'quizInChat':
    // Luồng 2/3 — asking how to start, handing the quiz over, offering the recap.
    case 'talkAsk':
    case 'quizHandoff':
    case 'quizRun':
    case 'talkWhen':
    case 'recapPick':
    case 'recapQuiz':
      return CoachSlimeMood.think;
    // The reader is telling: "thân dẹt xuống ổn định, mắt mở to".
    case 'tell':
    case 'tell2':
    case 'free':
    case 'jot':
    case 'tellOnce':
    case 'tellOnceA':
    case 'tellOnceB':
    case 'retryScene':
    case 'sceneRetry':
    case 'checkinTell':
    case 'talkSummary':
    // Luồng 2 — the open floor after the grading turn: the reader is asking,
    // so the Coach listens rather than weighs.
    case 'talkFree':
    case 'intentTell':
    case 'practiceAnswer':
    case 'nextAction':
    case 'story':
    case 'barrier':
    case 'contextEdit':
    // Luồng 1 — getting to know them: listening, never weighing.
    case 'onboardIntro':
    case 'onboardAddress':
    case 'onboardAddressConfirm':
    case 'onboardGoal':
    case 'onboardBarrier':
    case 'onboardCurrent':
    case 'onboardStyle':
    case 'onboardAge':
    case 'onboardGender':
    case 'onboardJob':
      return CoachSlimeMood.listen;
    // The tail: "nảy lên, mắt nhắm cong. Không reo hò, không huy hiệu."
    case 'moodEnd':
    case 'end':
    case 'leave':
    case 'rating':
    case 'closing':
    case 'nextSession':
    case 'courseCard':
      return CoachSlimeMood.cheer;
    default:
      return CoachSlimeMood.idle;
  }
}

/// One keyframe track: shared stops, one list of values per channel.
///
/// Sampled with an ease-in-out per segment, which is what the CSS animations
/// all declare — a linear lerp reads mechanical on a creature that is supposed
/// to be breathing.
class _Track {
  final List<double> stops;
  final List<List<double>> channels;

  const _Track(this.stops, this.channels);

  List<double> sample(double t) {
    var hi = 1;
    while (hi < stops.length - 1 && stops[hi] < t) {
      hi++;
    }
    final lo = hi - 1;
    final span = stops[hi] - stops[lo];
    final raw = span <= 0 ? 0.0 : ((t - stops[lo]) / span).clamp(0.0, 1.0);
    final eased = Curves.easeInOut.transform(raw);

    return [
      for (final channel in channels) channel[lo] + (channel[hi] - channel[lo]) * eased,
    ];
  }
}

/// Everything that differs between the seven states, straight from the
/// design's `MOODS` table. Times in seconds; geometry as fractions.
class _MoodSpec {
  /// Body-bob loop length.
  final double bob;

  /// Multiplier on the base viscosity (6s) — the shell's morph loop length.
  final double visc;

  /// Body transform: [tx, ty, sx, sy, rot°, skew°].
  final _Track body;

  /// Eye box, as fractions of the eye ROW's width (which is 56% of the body).
  final double eyeW;
  final double eyeH;
  final double gap;

  /// Bottom-corner radius as a fraction of eye width; null = full stadium.
  /// Only `cheer` squares the bottoms, which is what curves the closed eyes.
  final double? bottomRadius;

  /// Blink/expression: [sx, sy, tx, ty]. Null = eyes hold still (sleep).
  final _Track? eye;
  final double eyeDur;

  /// Eye-dart loop length; 0 = this state does not glance around.
  final double dart;

  /// Lightens (+) or darkens (−) the core, the design's mood tint.
  final double tint;

  const _MoodSpec({
    required this.bob,
    required this.visc,
    required this.body,
    required this.eyeW,
    required this.eyeH,
    required this.gap,
    this.bottomRadius,
    required this.eye,
    required this.eyeDur,
    required this.dart,
    required this.tint,
  });
}

// Body bobs — the design's sl-bob* keyframes, channels [tx,ty,sx,sy,rot,skew].
const _bobIdle = _Track(
  [0, .18, .38, .58, .78, 1],
  [
    [0, 0, 0, 0, 0, 0],
    [0, -.09, .03, -.05, .01, 0],
    [1, .9, 1.12, .95, 1.06, 1],
    [1, 1.11, .88, 1.06, .94, 1],
    [0, -3.5, 2, 4, -2, 0],
    [0, 2, -2.5, 1, -1.5, 0],
  ],
);
const _bobLean = _Track(
  [0, .3, .6, 1],
  [
    [0, -.09, -.05, 0],
    [0, -.08, .01, 0],
    [1, .9, 1.06, 1],
    [1, 1.14, .96, 1],
    [0, -9, -5, 0],
    [0, 6, 3, 0],
  ],
);
const _bobWide = _Track(
  [0, .5, 1],
  [
    [0, 0, 0],
    [.04, .06, .04],
    [1.16, 1.22, 1.16],
    [.86, .82, .86],
    [0, 1, 0],
    [0, 0, 0],
  ],
);
const _bobTall = _Track(
  [0, .35, .7, 1],
  [
    [0, 0, 0, 0],
    [-.04, -.07, -.03, -.04],
    [.84, .8, .88, .84],
    [1.2, 1.26, 1.14, 1.2],
    [6, 11, 4, 6],
    [0, -4, 2, 0],
  ],
);
const _bobHop = _Track(
  [0, .22, .44, .62, 1],
  [
    [0, 0, 0, 0, 0],
    [0, -.26, 0, -.11, 0],
    [1, .82, 1.24, .93, 1],
    [1, 1.22, .78, 1.08, 1],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ],
);
const _bobSag = _Track(
  [0, .5, 1],
  [
    [0, 0, 0],
    [.11, .14, .11],
    [1.14, 1.2, 1.14],
    [.8, .75, .8],
    [-2, -4, -2],
    [0, 0, 0],
  ],
);

// Blinks and expressions — sl-eye*, channels [sx, sy, tx, ty].
const _eyeIdle = _Track(
  [0, .26, .29, .32, .35, .38, .5, .66, .72, .78, 1],
  [
    [1, 1, 1.14, 1, 1.06, 1, .92, 1, 1.16, 1.04, 1],
    [1, 1, .1, 1, .55, 1, 1.14, 1, .08, .9, 1],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
);
const _eyeWide = _Track(
  [0, .92, .95, 1],
  [
    [1.06, 1.06, 1.14, 1.06],
    [1.12, 1.12, .1, 1.12],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
);
const _eyeHappy = _Track(
  [0, .4, .7, 1],
  [
    [1, 1, 1, 1],
    [1, 1.35, .85, 1],
    [0, 0, 0, 0],
    [0, -.10, .04, 0],
  ],
);
const _eyeDown = _Track(
  [0, .45, .75, 1],
  [
    [1, 1, 1, 1],
    [.8, .62, .14, .8],
    [0, -.14, 0, 0],
    [.24, .30, .26, .24],
  ],
);
const _eyeThink = _Track(
  [0, .22, .44, .62, .8, .86, 1],
  [
    [1, 1, 1, 1, 1, 1, 1],
    [1, .88, .95, 1.08, .1, .9, 1],
    [0, .20, -.16, .12, 0, 0, 0],
    [0, -.20, -.14, -.04, 0, 0, 0],
  ],
);

// The shell's wobble — sl-morph. Eight radii: hTL,hTR,hBR,hBL / vTL,vTR,vBR,vBL.
const _morph = _Track(
  [0, .17, .34, .51, .68, .85, 1],
  [
    [.43, .62, .37, .58, .41, .54, .43],
    [.57, .38, .63, .42, .59, .46, .57],
    [.54, .44, .65, .36, .60, .41, .54],
    [.46, .56, .35, .64, .40, .59, .46],
    [.59, .41, .56, .66, .39, .47, .59],
    [.45, .63, .36, .57, .47, .64, .45],
    [.55, .37, .64, .43, .53, .36, .55],
    [.41, .59, .44, .34, .61, .53, .41],
  ],
);

// The eyes' slow wander with the body — sl-eyes: [tx, ty, rot°].
const _eyesDrift = _Track(
  [0, .18, .38, .58, .78, 1],
  [
    [0, -.08, .07, .04, -.03, 0],
    [0, -.14, .10, -.07, .04, 0],
    [0, -4, 2.5, 5, -2, 0],
  ],
);

// The quick glance-around — sl-dart: [tx, ty]. Replaces the drift where a
// state darts, exactly as the CSS cascade resolves the two animations.
const _eyesDart = _Track(
  [0, .34, .38, .50, .54, .68, .73, .84, 1],
  [
    [0, 0, .20, .19, -.14, -.15, .04, .03, 0],
    [0, 0, -.04, -.03, .03, .02, -.08, -.07, 0],
  ],
);

// The pupil highlight sliding around — sl-glint: [tx, ty, scale, opacity].
const _glint = _Track(
  [0, .3, .55, .78, 1],
  [
    [0, .38, .14, -.20, 0],
    [0, .12, -.20, .08, 0],
    [1, .8, 1.15, .9, 1],
    [.85, .6, 1, .7, .85],
  ],
);

// The inner blob's own drift — sl-core: [tx, ty, scale].
const _coreDrift = _Track(
  [0, .25, .55, .8, 1],
  [
    [0, -.05, .04, .02, 0],
    [0, .04, -.04, .03, 0],
    [1, 1.05, .94, 1.02, 1],
  ],
);

const Map<CoachSlimeMood, _MoodSpec> _specs = {
  CoachSlimeMood.idle: _MoodSpec(
    bob: 3.4,
    visc: 1,
    body: _bobIdle,
    eyeW: .26,
    eyeH: .34,
    gap: .13,
    eye: _eyeIdle,
    eyeDur: 5.4,
    dart: 7.5,
    tint: 0,
  ),
  CoachSlimeMood.waiting: _MoodSpec(
    bob: 2.2,
    visc: .8,
    body: _bobLean,
    eyeW: .27,
    eyeH: .40,
    gap: .18,
    eye: _eyeIdle,
    eyeDur: 3.4,
    dart: 4,
    tint: .1,
  ),
  CoachSlimeMood.listen: _MoodSpec(
    bob: 2.8,
    visc: 1.6,
    body: _bobWide,
    eyeW: .32,
    eyeH: .46,
    gap: .20,
    eye: _eyeWide,
    eyeDur: 7.5,
    dart: 9,
    tint: 0,
  ),
  CoachSlimeMood.think: _MoodSpec(
    bob: 5.2,
    visc: 1.4,
    body: _bobTall,
    eyeW: .24,
    eyeH: .32,
    gap: .09,
    eye: _eyeThink,
    eyeDur: 3.6,
    dart: 0,
    tint: -.08,
  ),
  CoachSlimeMood.cheer: _MoodSpec(
    bob: 1.3,
    visc: .55,
    body: _bobHop,
    eyeW: .30,
    eyeH: .13,
    gap: .20,
    bottomRadius: .45,
    eye: _eyeHappy,
    eyeDur: 1.9,
    dart: 0,
    tint: .14,
  ),
  CoachSlimeMood.gentle: _MoodSpec(
    bob: 6.5,
    visc: 2,
    body: _bobSag,
    eyeW: .24,
    eyeH: .22,
    gap: .11,
    eye: _eyeDown,
    eyeDur: 8,
    dart: 0,
    tint: -.16,
  ),
  CoachSlimeMood.sleep: _MoodSpec(
    bob: 8.5,
    visc: 2.4,
    body: _bobSag,
    eyeW: .30,
    eyeH: .06,
    gap: .14,
    eye: null,
    eyeDur: 1,
    dart: 0,
    tint: -.22,
  ),
};

/// The Coach — a living blob of the skin colour.
///
/// Replaces the static circle face: the design gives the character a body that
/// never stops moving (a slow morph plus a per-state bob) and eyes that blink,
/// glance and close, because a coach that holds perfectly still reads as a
/// button, and this one is supposed to read as company.
///
/// One [Ticker] drives everything; the painter samples each keyframe track by
/// wall-clock phase, so seven concurrent CSS animations cost one repaint and no
/// layout. The ticker mutes with [TickerMode] (covered routes stop paying for
/// it), and when the platform asks for reduced motion the character holds a
/// resting pose instead of animating.
class CoachSlime extends StatefulWidget {
  final CoachSlimeMood mood;
  final double size;
  final Color color;

  /// The floating bubble carries the design's drop-shadow; the small avatars
  /// do not. Painted inside the painter so it follows the morphing outline —
  /// a box shadow behind a blob reads as a circular halo.
  final bool shadow;

  const CoachSlime({
    super.key,
    required this.mood,
    required this.size,
    this.color = CoachStyle.skin,
    this.shadow = false,
  });

  @override
  State<CoachSlime> createState() => _CoachSlimeState();
}

class _CoachSlimeState extends State<CoachSlime> with SingleTickerProviderStateMixin {
  /// The design's "Vừa" viscosity — the base the per-state multiplier scales.
  static const double _baseViscosity = 6;

  late final Ticker _ticker;
  final ValueNotifier<double> _elapsed = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(
      (elapsed) => _elapsed.value = elapsed.inMilliseconds / 1000,
    )..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _ticker.isActive) {
      _ticker.stop();
    } else if (!reduceMotion && !_ticker.isActive) {
      _ticker.start();
    }

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size.w),
        painter: _SlimePainter(
          elapsed: _elapsed,
          spec: _specs[widget.mood]!,
          color: widget.color,
          viscosity: _baseViscosity,
          shadow: widget.shadow,
        ),
      ),
    );
  }
}

class _SlimePainter extends CustomPainter {
  final ValueNotifier<double> elapsed;
  final _MoodSpec spec;
  final Color color;
  final double viscosity;
  final bool shadow;

  _SlimePainter({
    required this.elapsed,
    required this.spec,
    required this.color,
    required this.viscosity,
    required this.shadow,
  }) : super(repaint: elapsed);

  double _phase(double duration) {
    if (duration <= 0) return 0;
    final t = (elapsed.value / duration) % 1;
    return t < 0 ? t + 1 : t;
  }

  RRect _blob(Rect rect, List<double> radii) {
    return RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.elliptical(radii[0] * rect.width, radii[4] * rect.height),
      topRight: Radius.elliptical(radii[1] * rect.width, radii[5] * rect.height),
      bottomRight: Radius.elliptical(radii[2] * rect.width, radii[6] * rect.height),
      bottomLeft: Radius.elliptical(radii[3] * rect.width, radii[7] * rect.height),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    // ---- body transform (the bob), around the centre like CSS's default.
    final body = spec.body.sample(_phase(spec.bob));
    canvas.save();
    canvas.translate(center.dx + body[0] * s, center.dy + body[1] * s);
    canvas.rotate(body[4] * pi / 180);
    if (body[5] != 0) {
      canvas.transform(
        (Matrix4.identity()..setEntry(0, 1, tan(body[5] * pi / 180))).storage,
      );
    }
    canvas.scale(body[2], body[3]);
    canvas.translate(-center.dx, -center.dy);

    // ---- shell: the translucent skin, morphing.
    final shellRadii = _morph.sample(_phase(viscosity * spec.visc));
    final shell = _blob(Offset.zero & size, shellRadii);

    // Before the clip, so the blur can spill past the body the way a shadow
    // does. `drop-shadow(0 12px 22px rgba(0,0,0,.42))`, scaled to the size.
    if (shadow) {
      canvas.drawRRect(
        shell.shift(Offset(0, s * .2)),
        Paint()
          ..color = Colors.black.withValues(alpha: .42)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .18),
      );
    }

    canvas.clipRRect(shell);

    final shellPaint = Paint()
      ..shader = dartui.Gradient.radial(
        Offset(size.width * .30, size.height * .20),
        s * 1.2,
        [
          Colors.white.withValues(alpha: .55),
          color.withValues(alpha: .22),
          color.withValues(alpha: .40),
        ],
        const [0, .42, 1],
      );
    canvas.drawRRect(shell, shellPaint);

    // ---- core: the near-opaque inner blob that carries the colour. Its morph
    // runs in reverse on its own clock so shell and core never sync up — the
    // out-of-phase wobble is what sells "liquid".
    final coreRect = Rect.fromLTRB(
      size.width * .08,
      size.height * .08,
      size.width * .92,
      size.height * .92,
    );
    final coreRadii = _morph.sample(1 - _phase(viscosity * .78));
    final drift = _coreDrift.sample(_phase(spec.bob * 1.3));
    final topAlpha = (.95 + spec.tint).clamp(.45, 1.0);
    final bottomAlpha = (.75 + spec.tint).clamp(.35, 1.0);

    canvas.save();
    canvas.translate(
      coreRect.center.dx + drift[0] * coreRect.width,
      coreRect.center.dy + drift[1] * coreRect.height,
    );
    canvas.scale(drift[2]);
    canvas.translate(-coreRect.center.dx, -coreRect.center.dy);
    canvas.drawRRect(
      _blob(coreRect, coreRadii),
      Paint()
        ..shader = dartui.Gradient.radial(
          Offset(size.width * .34, size.height * .26),
          s * 1.1,
          [
            color.withValues(alpha: topAlpha),
            color,
            color.withValues(alpha: bottomAlpha),
          ],
          const [0, .55, 1],
        ),
    );
    canvas.restore();

    // ---- the static gloss stripe. Only at bubble size: the drawing puts it on
    // the 60px character and leaves it off the small avatars, where it would
    // just crowd the eyes.
    if (s >= 48) {
      final gloss = Rect.fromLTWH(
        size.width * .17,
        size.height * .13,
        size.width * .26,
        size.height * .17,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(gloss, Radius.circular(gloss.height)),
        Paint()..color = Colors.white.withValues(alpha: .5),
      );
    }

    // ---- eyes. The row wanders with the body; states that glance around swap
    // the slow drift for the darting track (the CSS cascade does the same —
    // the dart animation overrides the drift on the shared property).
    final rowWidth = s * .56;
    final eyeWidth = spec.eyeW * rowWidth;
    final eyeHeight = spec.eyeH * rowWidth;
    final gap = spec.gap * rowWidth;

    final rowTrack = spec.dart > 0 ? _eyesDart : _eyesDrift;
    final rowSample = rowTrack.sample(
      _phase(spec.dart > 0 ? spec.dart : spec.bob),
    );
    final rowRot = rowTrack == _eyesDrift ? rowSample[2] : 0.0;

    canvas.save();
    canvas.translate(
      center.dx + rowSample[0] * rowWidth,
      center.dy + rowSample[1] * eyeHeight,
    );
    canvas.rotate(rowRot * pi / 180);

    final blink = spec.eye?.sample(_phase(spec.eyeDur)) ?? const [1.0, 1.0, 0.0, 0.0];
    final glint = _glint.sample(_phase((spec.dart > 0 ? spec.dart : 9) * .7));

    for (final side in const [-1, 1]) {
      final eyeCenter = Offset(side * (gap / 2 + eyeWidth / 2), 0);

      canvas.save();
      canvas.translate(
        eyeCenter.dx + blink[2] * eyeWidth,
        eyeCenter.dy + blink[3] * eyeHeight,
      );
      canvas.scale(blink[0], blink[1]);

      final eyeRect = Rect.fromCenter(
        center: Offset.zero,
        width: eyeWidth,
        height: eyeHeight,
      );
      final stadium = Radius.circular(eyeWidth);
      final bottom = spec.bottomRadius == null ? stadium : Radius.circular(spec.bottomRadius! * eyeWidth);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          eyeRect,
          topLeft: stadium,
          topRight: stadium,
          bottomLeft: bottom,
          bottomRight: bottom,
        ),
        Paint()..color = CoachStyle.eye,
      );

      // The sliding highlight that keeps the pupil looking wet.
      final glintRect = Rect.fromLTWH(
        eyeRect.left + eyeRect.width * .18,
        eyeRect.top + eyeRect.height * .15,
        eyeRect.width * .40,
        eyeRect.height * .30,
      );
      canvas.save();
      canvas.translate(glint[0] * glintRect.width, glint[1] * glintRect.height);
      canvas.scale(glint[2]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(glintRect, Radius.circular(glintRect.height)),
        Paint()..color = Colors.white.withValues(alpha: .9 * glint[3]),
      );
      canvas.restore();

      canvas.restore();
    }
    canvas.restore();

    // ---- rim, over everything: the thin bright edge the CSS border gives.
    canvas.drawRRect(
      shell.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, s / 60)
        ..color = Colors.white.withValues(alpha: .45),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SlimePainter oldDelegate) {
    return oldDelegate.spec != spec || oldDelegate.color != color || oldDelegate.shadow != shadow || oldDelegate.elapsed != elapsed;
  }
}
