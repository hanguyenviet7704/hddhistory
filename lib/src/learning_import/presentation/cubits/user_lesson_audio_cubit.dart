part of '../../learning_import.dart';

/// Narration for a generated lesson.
///
/// Drives [LessonAudioHandler] directly — the app-lifetime `audio_service`
/// singleton registered at bootstrap — rather than going through
/// [LessonAudioCubit]. Two reasons:
///
/// [LessonAudioCubit] is built around a [KeypointEntity]: `configure` reads five
/// getters off one, its state carries a `keypointId`, and its cue lookup is
/// keyed by `(learningItemId, documentIndex)`. A generated lesson has none of
/// those. Teaching it a second shape would mean a second set of branches through
/// 1200 lines that currently serve the catalogue reader only.
///
/// And that file is where the background listening chain lives — work that
/// landed on develop the same day this was written and is not yet verified on a
/// device. Sitting beside it costs nothing; editing it risks something real.
///
/// The handler is a SINGLE player, which is the app's existing model ("one
/// narration at a time"). Loading a lesson here therefore stops keypoint
/// narration, and vice versa. That is intended, not a bug — but it is the
/// behaviour to check by hand.
@injectable
class UserLessonAudioCubit extends Cubit<UserLessonAudioState> {
  final LessonAudioHandler _handler;

  UserLessonAudioEntity? _audio;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  UserLessonAudioCubit(this._handler) : super(UserLessonAudioState.initial());

  /// Point the player at a lesson without starting it.
  ///
  /// Does NOT autoplay: the reader opens on a card, and a voice starting
  /// unbidden while someone is reading in a quiet room is the kind of thing they
  /// only forgive once.
  Future<void> attach(UserLessonEntity lesson) async {
    if (!lesson.canListen) return;
    if (state.lessonId == lesson.id) return;

    _audio = lesson.audio;
    emit(UserLessonAudioState.initial().copyWith(
      lessonId: lesson.id,
      duration: Duration(milliseconds: lesson.audio!.durationMs),
    ));

    _listen();

    await _handler.loadItem(
      url: lesson.audio!.url,
      id: lesson.id,
      title: lesson.title,
      // No cover art for a lesson made from someone's own PDF; the lock screen
      // falls back to the app icon.
      artUri: '',
      // Same reasoning as the merged keypoint file: the CDN serves these with
      // no edge cache, and neither AVPlayer nor ExoPlayer persists streamed
      // media, so without this every re-entry re-downloads the whole thing.
      cacheToDisk: true,
    );
  }

  void _listen() {
    _cancelSubscriptions();

    _subscriptions.add(
      _handler.playerStateStream.listen((playerState) {
        emit(state.copyWith(
          isPlaying: playerState.playing,
          isLoading:
              playerState.processingState == just_audio.ProcessingState.loading ||
              playerState.processingState == just_audio.ProcessingState.buffering,
        ));
      }),
    );

    _subscriptions.add(
      _handler.positionStream.listen((position) {
        final audio = _audio;
        if (audio == null) return;

        emit(state.copyWith(
          position: position,
          voiceCardIndex: audio.cardAt(position),
        ));
      }),
    );

    _subscriptions.add(
      _handler.durationStream.listen((duration) {
        // Only widen: the cue map's total is known before the file loads, and
        // the platform reports null then a real value. Taking whatever arrives
        // would blank the progress bar for a frame on every load.
        if (duration != null && duration > state.duration) {
          emit(state.copyWith(duration: duration));
        }
      }),
    );
  }

  Future<void> play() => _handler.play();

  Future<void> pause() => _handler.pause();

  Future<void> toggle() => state.isPlaying ? pause() : play();

  /// Jump the voice to a card the reader swiped to.
  ///
  /// One-way on purpose: the deck follows the voice through
  /// [UserLessonAudioState.voiceCardIndex], and the voice follows the deck only
  /// when the reader moves it themselves. Making both directions automatic makes
  /// them fight — a seek moves the deck, which seeks again.
  Future<void> seekToCard(int cardIndex) async {
    final audio = _audio;
    if (audio == null) return;

    await _handler.seek(audio.startOfCard(cardIndex));
  }

  Future<void> setSpeed(double speed) async {
    await _handler.setSpeed(speed);
    emit(state.copyWith(speed: speed));
  }

  /// Stop and let go of the player.
  ///
  /// Called when the reader leaves. Without it the narration would keep playing
  /// over whatever screen came next, which for a single-player handler means it
  /// would also still be holding the lock screen.
  Future<void> detach() async {
    _cancelSubscriptions();
    _audio = null;
    if (state.lessonId.isNotEmpty) await _handler.stop();
    emit(UserLessonAudioState.initial());
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  /// Stops the player when the reader leaves.
  ///
  /// The handler outlives this cubit — it is an app-lifetime singleton — so
  /// without stopping it here the narration would carry on over whatever screen
  /// came next, still holding the lock screen, with nothing left in the widget
  /// tree able to pause it.
  ///
  /// That does mean background listening ends when the reader closes the deck.
  /// Deliberate for now: letting it play on is only useful once something else
  /// can control it, and inventing that surface is a separate piece of work.
  @override
  Future<void> close() {
    _cancelSubscriptions();
    if (state.lessonId.isNotEmpty) unawaited(_handler.stop());

    return super.close();
  }
}
