part of '../../../../lesson.dart';

/// Carries the [ScrollController] that [_CardContentLayout] should hand to the
/// card's content scroller, so narration can scroll the text for the reader.
///
/// Provided ONLY around the live theory card ([NarrationAutoScroll]). Quiz cards
/// never provide it — a question is read aloud but the reader's eyes are on the
/// options, and moving the card under them mid-answer is hostile — so their
/// content scroller keeps its own implicit controller and stays entirely manual.
class NarrationScrollScope extends InheritedWidget {
  const NarrationScrollScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ScrollController controller;

  static ScrollController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NarrationScrollScope>()?.controller;
  }

  @override
  bool updateShouldNotify(NarrationScrollScope oldWidget) => controller != oldWidget.controller;
}

/// Scrolls the card's text along with its narration, so a card longer than the
/// screen reads itself without the reader having to drag it.
///
/// The mapping is deliberately the crudest one that works: elapsed / duration of
/// THIS card's own clip, applied to the scroller's full extent. Per-card clips
/// (see `KeypointCardCubit`) are what make that honest — the clip covers exactly
/// the text on this card and nothing else, so "40% through the audio" really is
/// "40% down the card". No sentence timings are needed, and none are available
/// from the TTS tier we dub with.
///
/// [LessonAudioState.positionSeconds] only ticks once per second, so each tick
/// animates toward where the NEXT tick will be, linearly over that second: the
/// text creeps continuously instead of stepping, and never trails a second
/// behind the voice.
///
/// A manual drag always wins. Touching the text suspends following for
/// [_manualGrace] after the drag ends, which is also what makes re-reading a
/// paragraph possible; when it resumes it glides back to the voice rather than
/// jumping.
class NarrationAutoScroll extends StatefulWidget {
  const NarrationAutoScroll({super.key, required this.cardIndex, required this.child});

  /// Which card this is, checked against
  /// [KeypointCardCubit.loadedClipCardIndex] on every tick: the card being read
  /// is the only one that may move, and it is only followed while the player
  /// really is on that card's own clip.
  ///
  /// Every theory card wraps itself in this widget regardless of whether it is the
  /// one being read — the controller has to stay attached to the same scroller for
  /// the card's whole life, or the offset snaps back to the top mid-swipe as the
  /// card is left behind.
  final int cardIndex;

  final Widget child;

  @override
  State<NarrationAutoScroll> createState() => _NarrationAutoScrollState();
}

class _NarrationAutoScrollState extends State<NarrationAutoScroll> {
  final ScrollController _controller = ScrollController();

  /// How long a manual drag keeps narration from scrolling the text.
  static const _manualGrace = Duration(seconds: 3);

  /// One tick of [LessonAudioState.positionSeconds] — the window each animation
  /// has to cover the ground to the next tick's target.
  static const _tick = Duration(seconds: 1);

  Timer? _manualGraceTimer;
  bool _isManual = false;

  /// Clip the last target was computed for. A new clip (swiping to another card)
  /// clears any manual suspension: that card's narration starts from its top.
  String _clipUrl = '';

  @override
  void dispose() {
    _manualGraceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onUserScrollStart() {
    _manualGraceTimer?.cancel();
    _isManual = true;
  }

  void _onUserScrollEnd() {
    _manualGraceTimer?.cancel();
    _manualGraceTimer = Timer(_manualGrace, () => _isManual = false);
  }

  void _followNarration(BuildContext context, LessonAudioState audioState) {
    if (audioState.sourceUrl != _clipUrl) {
      _clipUrl = audioState.sourceUrl;
      _manualGraceTimer?.cancel();
      _isManual = false;
    }

    // Read at tick time, not at build time: which card the player is on changes
    // without this widget being rebuilt.
    if (context.read<KeypointCardCubit>().loadedClipCardIndex != widget.cardIndex) return;
    if (_isManual || !audioState.isPlaying) return;
    if (!_controller.hasClients) return;

    final duration = audioState.durationSeconds;
    if (duration <= 0) return;

    final position = _controller.position;
    if (position.maxScrollExtent <= 0) return; // content fits — nothing to follow

    // Aim at the next tick, not this one, so the text arrives with the voice
    // instead of a second after it.
    final progress = ((audioState.positionSeconds + _tick.inSeconds) / duration).clamp(0.0, 1.0);
    final target = progress * position.maxScrollExtent;
    if ((target - position.pixels).abs() < 1) return;

    unawaited(_controller.animateTo(target, duration: _tick, curve: Curves.linear));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LessonAudioCubit, LessonAudioState>(
      listenWhen: (previous, current) =>
          previous.positionSeconds != current.positionSeconds || previous.isPlaying != current.isPlaying || previous.sourceUrl != current.sourceUrl,
      listener: _followNarration,
      // `dragDetails` is what separates the reader's finger from this widget's
      // own animateTo — both drive the same scroller and emit the same
      // notifications, and only the former should stop narration following.
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth != 0) return false;
          if (notification is ScrollStartNotification && notification.dragDetails != null) {
            _onUserScrollStart();
          } else if (notification is ScrollEndNotification && _isManual) {
            _onUserScrollEnd();
          }
          return false;
        },
        child: NarrationScrollScope(controller: _controller, child: widget.child),
      ),
    );
  }
}
