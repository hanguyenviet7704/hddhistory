part of '../../lesson.dart';

/// The keypoint background listening may read next, or null when the chain ends
/// here.
///
/// Pure on purpose — every rule that decides how far a hands-free listen carries
/// lives in this one function, so it can be reasoned about (and tested) without a
/// player, a route or a network.
///
/// The rules (product call, 2026-08-10):
/// - Lesson order, one step at a time. The chain never leaves the lesson.
/// - A keypoint with no usable merged file STOPS the chain rather than being
///   skipped: a keypoint the voice jumped over is one the reader believes they
///   heard, and it would never be marked complete.
/// - A paywalled keypoint stops it too — reading it aloud on the lock screen
///   hands over paid content just as surely as showing it.
/// - A keypoint already completed does NOT stop it: someone re-listening to a
///   finished lesson should keep hearing it through.
KeypointEntity? resolveChainCandidate({
  required LessonEntity lesson,
  required String currentKeypointId,
  required bool Function(KeypointEntity keypoint) isPaywallGated,
}) {
  if (currentKeypointId.isEmpty) return null;
  final keypoints = lesson.keypoints;
  final index = keypoints.indexWhere((keypoint) => keypoint.id == currentKeypointId);
  if (index < 0 || index + 1 >= keypoints.length) return null;

  final next = keypoints[index + 1];
  if (next.id.isEmpty) return null;
  final merged = next.resolvedMergedAudio;
  if (merged == null || !merged.isUsable) return null;
  if (isPaywallGated(next)) return null;
  return next;
}

/// Carries a hands-free listen across keypoint boundaries: queues the next
/// keypoint's narration while the current one plays, and moves the app onto the
/// keypoint the voice walked into.
///
/// The one place that knows WHICH keypoint may come next. [LessonAudioCubit]
/// owns the playlist and reports hops; this owns the policy — when to arm, what
/// the paywall says, and what a finished keypoint means for progress.
///
/// Not a Cubit: it publishes no UI state. Owned by [LessonPage], which creates
/// it in `initState` and disposes it — the same route scope as the
/// [LessonAudioCubit] it drives.
class ListenChainController with WidgetsBindingObserver {
  ListenChainController({
    required LessonAudioCubit audioCubit,
    required LessonCubit lessonCubit,
    required CourseLessonCubit courseLessonCubit,
  }) : _audioCubit = audioCubit,
       _lessonCubit = lessonCubit,
       _courseLessonCubit = courseLessonCubit {
    WidgetsBinding.instance.addObserver(this);
    _hopSubscription = _audioCubit.keypointHops.listen(_onHop);
    // Pressing play again on the lock screen re-opens the chain the pause closed
    // (the pause dropped the tail — see `LessonAudioCubit`'s `onOsPause`), so
    // playback STARTING is an arming moment. Only the transition: the audio cubit
    // re-emits on every position tick, and re-resolving the candidate once a
    // second would walk the whole roadmap for nothing.
    var wasPlaying = _audioCubit.state.isPlaying;
    _audioSubscription = _audioCubit.stream.listen((audioState) {
      final startedPlaying = audioState.isPlaying && !wasPlaying;
      wasPlaying = audioState.isPlaying;
      if (!startedPlaying) return;
      unawaited(_arm());
    });
  }

  final LessonAudioCubit _audioCubit;
  final LessonCubit _lessonCubit;
  final CourseLessonCubit _courseLessonCubit;

  StreamSubscription<({String from, String to})>? _hopSubscription;
  StreamSubscription<LessonAudioState>? _audioSubscription;

  /// Guards [_arm] against overlapping calls — see the comment there.
  bool _armInFlight = false;

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_hopSubscription?.cancel());
    unawaited(_audioSubscription?.cancel());
    _hopSubscription = null;
    _audioSubscription = null;
  }

  /// Same reading of the lifecycle as [KeypointCardCubit]: `inactive` (notification
  /// centre, an incoming call) and a null state count as ON screen — never queue a
  /// keypoint ahead on a guess.
  bool get _isBackgrounded {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return !(lifecycle == null || lifecycle == AppLifecycleState.resumed || lifecycle == AppLifecycleState.inactive);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isBackgrounded) {
      unawaited(_arm());
      return;
    }
    // Back on screen the deck owns narration again, and the foreground rules
    // (park at the recap, wait for Continue) must hold — so the queued keypoint
    // goes away. The one in flight finishes normally.
    unawaited(_audioCubit.dropQueuedTail());
  }

  /// Queues the next keypoint, if there is one and this is the moment for it.
  /// Idempotent: called from the lifecycle change, from playback resuming, and
  /// after every hop, and does nothing when a keypoint is already queued.
  Future<void> _arm() async {
    // Appending is async, and this is called from three places at once (lifecycle,
    // playback starting, a hop). Without the latch two overlapping calls both pass
    // the `hasQueuedNext` check and queue the SAME keypoint twice — the reader
    // hears it read out two times in a row.
    if (_armInFlight) return;
    if (!_isBackgrounded) return;
    if (_audioCubit.hasQueuedNext) return;
    // Silence the reader asked for is not a listening session to extend.
    if (_audioCubit.pausedByUser) return;
    if (!_audioCubit.isMergedMode || !_audioCubit.state.isReady) return;

    final candidate = resolveChainCandidate(
      lesson: _courseLessonCubit.state.selectedLesson,
      currentKeypointId: _audioCubit.state.keypointId,
      isPaywallGated: _isPaywallGated,
    );
    if (candidate == null) {
      // The chain ending is a normal outcome (last keypoint, paywall, no dub) but
      // it is also what a BROKEN chain looks like from the outside — and it
      // happens off screen, where nothing else is observable.
      LogDev.warning('[ListenChain] nothing to queue after ${_audioCubit.state.keypointId}');
      return;
    }

    _armInFlight = true;
    try {
      final queued = await _audioCubit.appendKeypoint(candidate);
      LogDev.warning('[ListenChain] queued=${candidate.id} ok=$queued');
    } finally {
      _armInFlight = false;
    }
  }

  /// The voice has crossed out of `hop.from` and into `hop.to`. Three things
  /// follow, in this order.
  void _onHop(({String from, String to}) hop) {
    // 1. The keypoint just left was heard out, and hearing a keypoint out IS
    //    finishing it (the same product line the final theory card follows).
    //    Filed BEFORE the reset below, because `completeCurrentKeypoint` reads
    //    the keypoint off the lesson's live item.
    //
    //    Only when the lesson really is still on the keypoint the voice left: a
    //    lesson whose items never loaded would otherwise file progress under an
    //    empty keypoint id.
    //
    //    `bypassReviewQueue` is not optional: `completeCurrentKeypoint` otherwise
    //    pushes ReviewTimeRoute, i.e. navigates the app while it sits in the
    //    background with the screen locked.
    LogDev.warning('[ListenChain] hop ${hop.from} -> ${hop.to}');
    final liveKeypointId = _lessonCubit.state.currentLearningItem.keypointId;
    if (liveKeypointId.isNotEmpty && liveKeypointId == hop.from) {
      _lessonCubit.completeCurrentKeypoint(
        origin: LessonCompletionOrigin.audio,
        bypassReviewQueue: true,
      );
    } else {
      LogDev.warning('listen chain: hop from ${hop.from} but the lesson is on "$liveKeypointId" — progress left alone');
    }

    // 2. Move the app itself onto the keypoint being read. This is the ordinary
    //    in-place keypoint switch (`LessonPage` listens for it) minus the audio
    //    half: `_syncAudioKeypoint` sees the player is already on this keypoint
    //    and adopts it instead of reloading the file mid-sentence.
    _courseLessonCubit.setCurrentKeypointId(hop.to);
    _lessonCubit
      ..reset()
      ..loadAllLearningItems(keypointId: hop.to, isInit: true);

    // 3. Stay exactly one keypoint ahead, so the next hop is queued in time and
    //    every step re-checks the paywall.
    unawaited(_arm());
  }

  /// Whether the in-lesson paywall would gate [keypoint].
  ///
  /// Mirrors `KeypointCardShell._inLessonPaywallCap` (config → premium →
  /// keypoint ordinal across the roadmap), with one deliberate difference: it
  /// fails **CLOSED**. That shell fails open because a paywall it cannot evaluate
  /// must not make a lesson unreadable; here the cost of being wrong is only that
  /// the chain stops, against the cost of reading a paid keypoint out loud.
  ///
  /// Everything comes from `AppDI.injector` for the same reason it does there:
  /// the lesson route provides neither `ProfileCubit` nor `CourseRoadmapCubit`.
  bool _isPaywallGated(KeypointEntity keypoint) {
    try {
      final config = AppDI.injector.get<IapCubit>().resolvedPaywallConfig.inLessonPaywall;
      if (!config.enabled) return false;
      if (AppDI.injector.get<ProfileCubit>().state.user.isPremium) return false;
      // Same convention as the shell: a non-positive ordinal gates every keypoint.
      if (config.keypointOrdinal <= 0) return true;

      final lessons = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap.flatLessons;
      var ordinal = 0;
      for (final lesson in lessons) {
        for (final candidate in lesson.keypoints) {
          ordinal++;
          if (candidate.id == keypoint.id) return ordinal >= config.keypointOrdinal;
        }
      }
      // Not in the roadmap at all (an entry flow that never populated it, e.g. a
      // Live Activity resume): the keypoint's ordinal is unknowable, so the chain
      // stops rather than guesses. Logged because from the outside this is
      // indistinguishable from the feature simply not working.
      LogDev.warning('listen chain: ${keypoint.id} not found in the roadmap — ending the chain');
      return true;
    } catch (error, stackTrace) {
      LogDev.error('listen chain paywall check failed; ending the chain: $error\n$stackTrace');
      return true;
    }
  }
}
