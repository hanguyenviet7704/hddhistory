part of '../../learning_import.dart';

/// The number the import progress bars actually draw, 0..1.
///
/// The server's `percent` is not a progress measurement — it is a phase marker.
/// It only ever takes four values (0 queued → 5 fetching → 25 generating → 100
/// completed), and the 25 covers the entire model stream, which is where nearly
/// all of the wait lives. Bound straight to a bar, that reads as a broken
/// loader: three jumps with dead stops between them, the longest of which parks
/// at a quarter full for minutes.
///
/// So the phase marker sets a CEILING and this fills the phase itself. The value
/// eases toward that ceiling exponentially — fast at first, ever slower — which
/// has three properties the naive versions lack:
///
/// * it never stops moving, because an exponential approach never arrives;
/// * it never reaches the ceiling, so it cannot promise a phase is done before
///   the server says so — 95% is as far as generation can ever look;
/// * a phase change only raises the ceiling, so the bar never jumps backwards
///   and never lurches forward either. The rate changes; the value stays
///   continuous.
///
/// It lives on [LearningImportCubit] rather than inside either bar because the
/// reader moves between the two of them: minimising the waiting screen swaps the
/// full-page bar for the shell toast, and a per-widget animation would restart
/// from zero — or snap back to the server's 25 — at exactly that moment. One
/// value, two views. A [ValueNotifier] rather than cubit state so a 12 Hz tick
/// rebuilds the bars alone instead of every listener the cubit has.
class ImportProgressCreep extends ValueNotifier<double> {
  ImportProgressCreep() : super(0);

  /// Tick period. Fast enough to read as motion, far cheaper than a frame
  /// callback, and irrelevant to the curve — [_tau] is in seconds, so the shape
  /// of the fill does not change if this does.
  static const Duration _tick = Duration(milliseconds: 80);

  Timer? _timer;
  double _ceiling = 0;
  double _tau = 1;

  /// Where the fill can reach in the phase [serverPercent] announces.
  ///
  /// The gap between marker and ceiling IS the phase: 5 says "fetching has
  /// started", so the bar may fill to a quarter while it runs; 25 says
  /// "the model is writing", the long one, so it may fill to nearly full.
  static double _ceilingFor(int serverPercent) {
    if (serverPercent >= 100) return 1;
    if (serverPercent >= 25) return 0.95;
    if (serverPercent >= 5) return 0.25;

    return 0.05;
  }

  /// Seconds to close ~63% of the remaining gap — the phase's expected length,
  /// roughly. Generation is the one that matters: 75s puts the bar near 70% at
  /// a minute and still inching at five, which covers both a 5-minute video
  /// (outline in seconds) and a 2-hour one without either looking wrong.
  static double _tauFor(int serverPercent) {
    if (serverPercent >= 100) return 0.12;
    if (serverPercent >= 25) return 75;
    if (serverPercent >= 5) return 10;

    return 2;
  }

  /// Feed the latest server reading.
  ///
  /// [isFailed] freezes the bar where it stands: a job that died has not made
  /// progress, and running the fill on to 95% under an error message would be
  /// the screen contradicting itself.
  void onJob({required int serverPercent, required bool isFailed}) {
    if (isFailed) {
      _stop();

      return;
    }

    _ceiling = math.max(_ceiling, _ceilingFor(serverPercent));
    _tau = _tauFor(serverPercent);
    _start();
  }

  /// Back to empty for a new run. Without this the next import would start from
  /// the last one's full bar.
  void restart() {
    _stop();
    _ceiling = 0;
    _tau = 1;
    value = 0;
  }

  void _start() {
    if (_timer != null) return;
    _timer = Timer.periodic(_tick, (_) => _step());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _step() {
    final remaining = _ceiling - value;
    // Close enough to the ceiling that further steps are sub-pixel: park until
    // the next phase raises it, rather than burning a timer on invisible work.
    if (remaining <= 0.0005) {
      value = _ceiling;
      _stop();

      return;
    }

    // Exponential approach: a fixed FRACTION of what is left, each tick. Framed
    // in seconds via [_tau] so the curve is independent of the tick rate.
    final step = 1 - math.exp(-_tick.inMilliseconds / 1000 / _tau);
    value = value + remaining * step;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
