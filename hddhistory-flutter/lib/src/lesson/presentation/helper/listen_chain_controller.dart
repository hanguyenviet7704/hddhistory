part of '../../lesson.dart';

/// Why a hands-free listen ends where it does. Logged at every stop: the chain
/// runs off screen, so "it went quiet" is the only symptom either a normal end
/// or a broken one produces.
enum ChainStopReason {
  /// Nothing left on the roadmap after this keypoint.
  endOfRoadmap,

  /// The next roadmap stop isn't read out loud (roleplay, video, output
  /// practice). Stopping rather than skipping it: those types gate the roadmap,
  /// so reading past one narrates content the app itself has locked.
  nonReadableStop,

  /// The next keypoint is behind the in-lesson paywall.
  paywall,

  /// The next keypoint's roadmap tile is behind lesson lock.
  lessonLocked,

  /// The next keypoint has no usable merged dub. Stops rather than skips: a
  /// keypoint the voice jumped over is one the reader believes they heard, and
  /// it would never be marked complete.
  noMergedDub,

  /// Where the voice is can't be placed — no keypoint id, or the lesson detail
  /// doesn't contain the keypoint the roadmap points at.
  unknownPosition,
}

/// The next step background listening may take, or the reason it ends here.
///
/// Three cases rather than a nullable keypoint, because crossing a lesson
/// boundary is not something this function can resolve on its own: the roadmap
/// carries only a per-language legacy `url` for its keypoints, never the merged
/// dub the chain queues (the trap fixed in e17b179e). So a step out of the open
/// lesson comes back as ids for the caller to fetch.
sealed class ChainStep {
  const ChainStep();
}

/// The next keypoint belongs to the lesson already open — its merged dub is in
/// hand and can be queued immediately.
class ChainStepInLesson extends ChainStep {
  const ChainStepInLesson(this.keypoint);

  final KeypointEntity keypoint;
}

/// The next keypoint belongs to another lesson. The caller must load that
/// lesson's detail before anything can be queued.
class ChainStepNextLesson extends ChainStep {
  const ChainStepNextLesson({required this.lessonId, required this.keypointId});

  final String lessonId;
  final String keypointId;
}

/// The chain ends here.
class ChainStepEnd extends ChainStep {
  const ChainStepEnd(this.reason);

  final ChainStopReason reason;
}

/// Where a hands-free listen goes after [currentKeypointId].
///
/// Pure on purpose — every rule that decides how far a listen carries lives in
/// this one function, so it can be reasoned about (and tested) without a player,
/// a route or a network.
///
/// The rules (product calls, 2026-08-10 / 2026-08-11):
/// - **Roadmap order**, one step at a time, across lesson boundaries: what the
///   reader sees as the course's list of tiles IS the order they hear it in.
///   Each roadmap entry in [roadmapStops] is one keypoint
///   (`RoadmapNodeEntityExtension.lessonsList` expands a lesson per keypoint).
/// - A keypoint already completed does NOT stop it: someone re-listening to a
///   finished lesson should keep hearing it through.
/// - Everything that stops it is a [ChainStopReason].
///
/// [roadmapStops] not containing the current keypoint is not an error: a
/// generated (imported) lesson is on no roadmap. Those walk their own lesson's
/// keypoint order and can never cross a lesson — there is nothing to cross to.
ChainStep resolveChainStep({
  required List<LessonEntity> roadmapStops,
  required LessonEntity openLesson,
  required String currentKeypointId,
  required bool Function(KeypointEntity keypoint) isPaywallGated,
  required bool Function(LessonEntity roadmapStop) isLessonLocked,
}) {
  if (currentKeypointId.isEmpty) return const ChainStepEnd(ChainStopReason.unknownPosition);

  final index = roadmapStops.indexWhere((stop) => stop.roadmapKey == currentKeypointId);
  if (index < 0) {
    return _stepWithinLesson(
      lesson: openLesson,
      currentKeypointId: currentKeypointId,
      isPaywallGated: isPaywallGated,
    );
  }
  if (index + 1 >= roadmapStops.length) return const ChainStepEnd(ChainStopReason.endOfRoadmap);

  final next = roadmapStops[index + 1];
  final nextKeypointId = next.roadmapKey;
  if (next.id.isEmpty || nextKeypointId.isEmpty) return const ChainStepEnd(ChainStopReason.unknownPosition);
  if (next.type != LessonType.lesson) return const ChainStepEnd(ChainStopReason.nonReadableStop);
  if (isLessonLocked(next)) return const ChainStepEnd(ChainStopReason.lessonLocked);
  // The roadmap's own stub keypoint is enough for the paywall check, which
  // places a keypoint by id. Its dub, however, is only in the lesson detail.
  if (isPaywallGated(next.firstKeypoint)) return const ChainStepEnd(ChainStopReason.paywall);

  if (next.id != openLesson.id) {
    return ChainStepNextLesson(lessonId: next.id, keypointId: nextKeypointId);
  }

  final keypoint = openLesson.keypoints.firstWhere(
    (candidate) => candidate.id == nextKeypointId,
    orElse: KeypointEntity.new,
  );
  if (keypoint.id.isEmpty) return const ChainStepEnd(ChainStopReason.unknownPosition);
  if (!hasChainableDub(keypoint)) return const ChainStepEnd(ChainStopReason.noMergedDub);
  return ChainStepInLesson(keypoint);
}

/// Lesson-order fallback for a lesson that is on no roadmap (a generated one).
ChainStep _stepWithinLesson({
  required LessonEntity lesson,
  required String currentKeypointId,
  required bool Function(KeypointEntity keypoint) isPaywallGated,
}) {
  final keypoints = lesson.keypoints;
  final index = keypoints.indexWhere((keypoint) => keypoint.id == currentKeypointId);
  if (index < 0) return const ChainStepEnd(ChainStopReason.unknownPosition);
  if (index + 1 >= keypoints.length) return const ChainStepEnd(ChainStopReason.endOfRoadmap);

  final next = keypoints[index + 1];
  if (next.id.isEmpty) return const ChainStepEnd(ChainStopReason.unknownPosition);
  if (!hasChainableDub(next)) return const ChainStepEnd(ChainStopReason.noMergedDub);
  if (isPaywallGated(next)) return const ChainStepEnd(ChainStopReason.paywall);
  return ChainStepInLesson(next);
}

/// Whether [keypoint] has a merged dub the chain can queue and follow.
bool hasChainableDub(KeypointEntity keypoint) {
  final merged = keypoint.resolvedMergedAudio;
  return merged != null && merged.isUsable;
}

/// Carries a hands-free listen down the roadmap — across keypoint AND lesson
/// boundaries: queues the next keypoint's narration while the current one plays,
/// and moves the app onto the keypoint (and, when it changed, the lesson) the
/// voice walked into. Started on the first tile of a course, it plays to the end
/// of what the reader is entitled to hear.
///
/// The one place that knows WHICH keypoint may come next. [LessonAudioCubit]
/// owns the playlist and reports hops; this owns the policy — when to arm, what
/// the two paywalls say, and what a finished keypoint means for progress.
///
/// Not a Cubit: it publishes no UI state. Owned by [LessonPage], which creates
/// it in `initState` and disposes it — the same route scope as the
/// [LessonAudioCubit] it drives.
class ListenChainController with WidgetsBindingObserver {
  ListenChainController({
    required LessonAudioCubit audioCubit,
    required LessonCubit lessonCubit,
    required CourseLessonCubit courseLessonCubit,
    CourseRoadmapCubit? roadmapCubit,
    GetCourseLessonUseCase? getCourseLesson,
  }) : _audioCubit = audioCubit,
       _lessonCubit = lessonCubit,
       _courseLessonCubit = courseLessonCubit,
       _roadmapCubit = roadmapCubit ?? AppDI.injector.get<CourseRoadmapCubit>(),
       _getCourseLesson = getCourseLesson ?? AppDI.injector.get<GetCourseLessonUseCase>() {
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
  final CourseRoadmapCubit _roadmapCubit;
  final GetCourseLessonUseCase _getCourseLesson;

  StreamSubscription<({String from, String to})>? _hopSubscription;
  StreamSubscription<LessonAudioState>? _audioSubscription;

  /// Guards [_arm] against overlapping calls — see the comment there.
  bool _armInFlight = false;

  /// Full detail of the lesson the QUEUED keypoint belongs to, when the queued
  /// keypoint is in a different lesson than the one open. Held from the moment
  /// it is queued until the voice walks into it, because that hop has to hand
  /// the app a lesson it can read from — the roadmap's stub carries no dub and
  /// no learning items.
  LessonEntity? _queuedLesson;

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
    _queuedLesson = null;
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
    if (!_canArm) return;

    final step = resolveChainStep(
      roadmapStops: _roadmapCubit.state.roadmap.displayLessons,
      openLesson: _courseLessonCubit.state.selectedLesson,
      currentKeypointId: _audioCubit.state.keypointId,
      isPaywallGated: _isPaywallGated,
      isLessonLocked: _isLessonLocked,
    );

    _armInFlight = true;
    try {
      switch (step) {
        // The chain ending is a normal outcome (end of the roadmap, paywall, no
        // dub) but it is also what a BROKEN chain looks like from the outside —
        // and it happens off screen, where nothing else is observable. Hence the
        // reason, always logged.
        case ChainStepEnd(:final reason):
          LogDev.warning('[ListenChain] nothing to queue after ${_audioCubit.state.keypointId} — ${reason.name}');
        case ChainStepInLesson(:final keypoint):
          final queued = await _audioCubit.appendKeypoint(keypoint);
          LogDev.warning('[ListenChain] queued=${keypoint.id} ok=$queued');
        case ChainStepNextLesson(:final lessonId, :final keypointId):
          await _armNextLesson(lessonId: lessonId, keypointId: keypointId);
      }
    } finally {
      _armInFlight = false;
    }
  }

  /// Whether this is a moment to queue anything at all.
  bool get _canArm {
    if (!_isBackgrounded) return false;
    if (_audioCubit.hasQueuedNext) return false;
    // Silence the reader asked for is not a listening session to extend.
    if (_audioCubit.pausedByUser) return false;
    return _audioCubit.isMergedMode && _audioCubit.state.isReady;
  }

  /// Queues the first keypoint of the NEXT lesson: fetches that lesson's detail
  /// (the roadmap stub has no merged dub) and queues out of it.
  ///
  /// Runs while the last keypoint of the open lesson is still playing — minutes
  /// of headroom — because a fetch AT the boundary is exactly what the queue
  /// exists to avoid (iOS suspends the app before it lands).
  Future<void> _armNextLesson({required String lessonId, required String keypointId}) async {
    final lesson = await _loadLessonDetail(lessonId);
    if (lesson == null) {
      LogDev.warning('[ListenChain] could not load lesson $lessonId — chain ends here');
      return;
    }

    final keypoint = lesson.keypoints.firstWhere(
      (candidate) => candidate.id == keypointId,
      orElse: KeypointEntity.new,
    );
    if (keypoint.id.isEmpty) {
      LogDev.warning('[ListenChain] lesson $lessonId has no keypoint $keypointId — ${ChainStopReason.unknownPosition.name}');
      return;
    }
    if (!hasChainableDub(keypoint)) {
      LogDev.warning('[ListenChain] $keypointId — ${ChainStopReason.noMergedDub.name}');
      return;
    }
    // The fetch took a round trip: the reader may have opened the app, paused on
    // the lock screen, or hopped since. Re-ask rather than queue into a session
    // whose rules changed underneath.
    if (!_canArm) return;

    final queued = await _audioCubit.appendKeypoint(keypoint);
    if (queued) _queuedLesson = lesson;
    LogDev.warning('[ListenChain] queued=$keypointId ok=$queued lesson=$lessonId (next lesson)');
  }

  /// The lesson detail, or null when it can't be had. Deliberately no retry: a
  /// failed fetch ends the chain (logged) instead of hammering the network from
  /// a backgrounded app.
  Future<LessonEntity?> _loadLessonDetail(String lessonId) async {
    final result = await _getCourseLesson(lessonId).run();
    return result.fold((exception) {
      LogDev.warning('[ListenChain] lesson $lessonId fetch failed: ${exception.message}');
      return null;
    }, (lesson) => lesson.id.isEmpty ? null : lesson);
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
    //
    //    When the voice walked into ANOTHER lesson, the lesson comes with it —
    //    in ONE emission (`enterLesson`), so the app never sees the moment where
    //    the new lesson is selected while `currentKeypointId` still names a
    //    keypoint of the old one: `resolvedCurrentKeypoint` would fall back to
    //    the new lesson's first keypoint and `LessonPage` would sync against a
    //    keypoint nobody is reading.
    final queuedLesson = _queuedLesson;
    final crossesLesson = queuedLesson != null && queuedLesson.keypoints.any((keypoint) => keypoint.id == hop.to);
    if (crossesLesson) {
      LogDev.warning('[ListenChain] crossing into lesson ${queuedLesson.id}');
      _queuedLesson = null;
      _courseLessonCubit.enterLesson(lesson: queuedLesson, keypointId: hop.to);
      _followRoadmapTo(hop.to);
    } else {
      _courseLessonCubit.setCurrentKeypointId(hop.to);
    }
    _lessonCubit
      ..reset()
      ..loadAllLearningItems(keypointId: hop.to, isInit: true);

    // 3. Stay exactly one keypoint ahead, so the next hop is queued in time and
    //    every step re-checks the paywall.
    unawaited(_arm());
  }

  /// Moves the roadmap's own selection onto the tile being read.
  ///
  /// Only matters when the chain crossed a lesson: otherwise closing the deck
  /// lands the reader back on the lesson they started an hour of listening ago,
  /// and — when the chain also crossed a LEVEL — on the wrong level's tab.
  void _followRoadmapTo(String keypointId) {
    final roadmap = _roadmapCubit.state.roadmap;
    final stop = roadmap.displayLessons.firstWhere(
      (candidate) => candidate.roadmapKey == keypointId,
      orElse: LessonEntity.new,
    );
    if (stop.id.isEmpty) return;

    for (final level in roadmap.levels) {
      if (level.roadmapLessonsList.any((candidate) => candidate.isSameLesson(stop))) {
        _roadmapCubit.setCurrentCourseLevel(level.level);
        break;
      }
    }
    _roadmapCubit.setCurrentLesson(stop);
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

      final lessons = _roadmapCubit.state.roadmap.flatLessons;
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

  /// Whether lesson lock covers [roadmapStop] — the SECOND paywall on the
  /// roadmap, independent of the in-lesson one: it hides whole tiles from
  /// `lessonLock` onwards (see `RoadmapEntityExtension.lockedLessonKeys`), which
  /// is what the padlocks on the roadmap are.
  ///
  /// Fails CLOSED, for the same reason [_isPaywallGated] does.
  bool _isLessonLocked(LessonEntity roadmapStop) {
    try {
      final config = AppDI.injector.get<IapCubit>().resolvedPaywallConfig;
      final isPremium = AppDI.injector.get<ProfileCubit>().state.user.isPremium;
      return _roadmapCubit.state.roadmap.isLessonLocked(roadmapStop, config, isPremium: isPremium);
    } catch (error, stackTrace) {
      LogDev.error('listen chain lesson-lock check failed; ending the chain: $error\n$stackTrace');
      return true;
    }
  }
}
