part of '../../lesson.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({
    super.key,
    required this.autoplayOnEntry,
  });

  /// Whether the FIRST keypoint synced after this page mounts should
  /// autoplay its narration immediately. Every keypoint synced AFTER the
  /// first one within the same session always autoplays regardless (the
  /// unified screen's standing behavior — narration follows the reader by
  /// default) — this only covers the initial "should the very first keypoint
  /// just start talking at me?" decision, sourced from the `initial-mode`
  /// route query (see `routes_shell_course_lesson_data.dart` /
  /// `LessonEntryMode` — repurposed from "which mode tab to open" to this).
  final bool autoplayOnEntry;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final LessonReviewBodyBuilder _reviewBodyBuilder;
  late final LessonBodyFactory _bodyFactory;
  late final LessonTrackingDelegate _trackingDelegate;
  late final LessonCubit _lessonCubit;
  late final LessonAudioCubit _lessonAudioCubit;

  /// Carries background listening across keypoint boundaries. Lives here because
  /// this is the one place that holds both the route's [LessonAudioCubit] and the
  /// [CourseLessonCubit] whose keypoint list the chain walks — and because the
  /// keypoint switch it performs comes straight back through
  /// [_syncAudioKeypoint].
  late final ListenChainController _listenChain;

  /// Applies reading-speed changes to the player. The speed control now lives
  /// as an inline stepper inside [KeypointSettingsSheet], which is a modal
  /// route and therefore sits OUTSIDE this page's provider scope — it can only
  /// write the persisted [KeypointDisplayCubit] value, so the page listens
  /// here and pushes it into the route-scoped [LessonAudioCubit].
  StreamSubscription<KeypointDisplayState>? _readingSpeedSubscription;

  bool _hasSyncedFirstKeypoint = false;

  /// Keypoint id the audio autoplay decision last ran for — a same-id re-sync
  /// (entity refresh) must not re-enter audio mode (see [_syncAudioKeypoint]).
  String _audioSyncedKeypointId = '';
  // Keypoint whose "đang nghe dở" bookmark has already been applied (or ruled
  // out) this session — the lesson emits `success` more than once and the
  // jump must not re-fire over a deck the reader is already driving.
  String _resumeAppliedForKeypoint = '';
  // One-shot guard re-asserting the resume jump if the entry flow's ASYNC
  // item-detail fetch lands after it and resets TheoryCubit to document 0 —
  // see [_applyListenResume].
  StreamSubscription<TheoryState>? _resumeGuard;
  String _lastTrackedScrollKey = '';
  // Source for the next keypoint_read_scr_view: 'keypoint_intro' on entry,
  // flipped to 'mode_switch' the moment the user switches into read mode.
  // Now only ever 'keypoint_intro' — the unified screen has no mode switch
  // left to flip it — kept as a field (rather than a literal) so a future
  // distinct entry source is a one-line change.
  final String _readViewSource = 'keypoint_intro';

  @override
  void initState() {
    super.initState();
    _lessonCubit = context.read<LessonCubit>();
    _lessonAudioCubit = context.read<LessonAudioCubit>();
    _listenChain = ListenChainController(
      audioCubit: _lessonAudioCubit,
      lessonCubit: _lessonCubit,
      courseLessonCubit: context.read<CourseLessonCubit>(),
    );
    _reviewBodyBuilder = const LessonReviewBodyBuilder();
    _bodyFactory = LessonBodyFactory(
      onAnswerChecked: _handleAnswerChecked,
      onContinueUnsupported: () => AppDI.injector.get<ExerciseCubit>().nextQuestion(),
      reviewBodyBuilder: _reviewBodyBuilder,
    );
    _trackingDelegate = const LessonTrackingDelegate();

    // Narration and the study background's ambient music talking at once makes
    // the voice hard to follow, so the lesson borrows the ears while it is open
    // and hands them back in `dispose`. Suspending rather than toggling the
    // reader's own preference is what lets that survive being killed mid-lesson
    // (see `StudyThemeCubit.suspendSound`).
    AppDI.injector.get<StudyThemeCubit>().suspendSound(true);

    final displayCubit = AppDI.injector.get<KeypointDisplayCubit>();
    var appliedSpeed = displayCubit.state.readingSpeed;
    _readingSpeedSubscription = displayCubit.stream.listen((state) {
      if (state.readingSpeed == appliedSpeed) return;
      appliedSpeed = state.readingSpeed;
      _lessonAudioCubit.setSpeed(state.readingSpeed);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Assert this page's (non-primary) route name so the shell's floating
      // nav pill stays hidden over the lesson. Otherwise the first-time
      // navigation popup (and any other overlay) shown below writes the
      // UNDERLYING primary route name (courseRoadmap) on dismissal, un-hiding
      // the nav over the CTA.
      _ensureLessonRouteName();
      await _syncAudioKeypoint(context.read<CourseLessonCubit>().state.resolvedCurrentKeypoint);
    });
  }

  @override
  void dispose() {
    _listenChain.dispose();
    unawaited(_resumeGuard?.cancel());
    unawaited(_readingSpeedSubscription?.cancel());
    // Leaving the lesson: the ambience comes back if the reader had it on, and
    // stays off if they didn't — the preference was never touched.
    AppDI.injector.get<StudyThemeCubit>().suspendSound(false);
    super.dispose();
  }

  /// Keeps the floating nav pill hidden while the lesson is shown. The pill is
  /// gated on [PageStateX.isPrimaryRoute]; overlays dismissed above this page
  /// make the route observer write the underlying (primary) route name, so we
  /// re-assert this page's name whenever it's flipped back — but only while the
  /// lesson is still the current route (mirrors keypoint_complete_page).
  void _ensureLessonRouteName() {
    if (!mounted) return;
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.lesson);
  }

  @override
  Widget build(BuildContext context) {
    final currentKeypoint = context.select((CourseLessonCubit cubit) => cubit.state.resolvedCurrentKeypoint);
    final isLoading = context.select((LessonCubit cubit) => cubit.state.status == LessonStatus.loading);

    return MultiBlocListener(
      listeners: [
        // Any overlay dismissed above this page (nav guide, report sheet, exit
        // flow…) makes the route observer write the UNDERLYING route's name — a
        // primary one (courseRoadmap) — which un-hides the floating nav over the
        // lesson's CTA. As long as the lesson is still the current route, take
        // the name back (mirrors keypoint_complete_page).
        BlocListener<PageCubit, PageState>(
          bloc: AppDI.injector.get<PageCubit>(),
          listenWhen: (previous, current) => previous.currentRouteName != current.currentRouteName && current.isPrimaryRoute,
          listener: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
              _ensureLessonRouteName();
            });
          },
        ),
        BlocListener<CourseLessonCubit, CourseLessonState>(
          listenWhen: (previous, current) => previous.resolvedCurrentKeypoint != current.resolvedCurrentKeypoint,
          listener: (context, state) async {
            await _syncAudioKeypoint(state.resolvedCurrentKeypoint);
          },
        ),
        // Resume "đang nghe dở": the audio already opened at the bookmarked
        // second (see [_syncAudioKeypoint]); once the learning items land the
        // deck is jumped to the matching card. Split on purpose — the sound is
        // right within a second of entry, the cards follow as soon as they
        // exist.
        BlocListener<LessonCubit, LessonState>(
          listenWhen: (previous, current) => previous.status != current.status && current.status == LessonStatus.success,
          listener: (context, lessonState) => _applyListenResume(lessonState),
        ),
        BlocListener<TheoryCubit, TheoryState>(
          listenWhen: (previous, current) {
            return previous.currentDocumentIndex != current.currentDocumentIndex ||
                previous.currentLearningItem.id != current.currentLearningItem.id ||
                previous.currentDocument.id != current.currentDocument.id;
          },
          listener: (context, state) {
            _trackingDelegate.trackKeypointTheoryScrView(state, source: _readViewSource);
          },
        ),
        BlocListener<ExerciseCubit, ExerciseState>(
          listenWhen: (previous, current) {
            return previous.currentQuestionIndex != current.currentQuestionIndex ||
                previous.currentLearningItem.id != current.currentLearningItem.id ||
                previous.currentQuestion.id != current.currentQuestion.id;
          },
          listener: (context, state) {
            _trackingDelegate.trackKeypointExerciseScrView(state, source: _readViewSource);
          },
        ),
        // Swiping to a different card is this screen's equivalent of the old
        // ListView's "scrolled a new item into view" signal.
        BlocListener<KeypointCardCubit, KeypointCardState>(
          listenWhen: (previous, current) => previous.viewedCardIndex != current.viewedCardIndex,
          listener: (context, state) {
            _trackCurrentLearningItemScroll();
            _saveImportedProgress(state.viewedCardIndex);
          },
        ),
      ],
      child: LessonShellLayout(
        onClose: () => LessonExitFlow.open(
          context,
          onBeforePopup: () {
            context.read<LessonAudioCubit>().pauseForOverlay();
            return Future.value();
          },
        ),
        trailing: LessonHeaderMenu(
          onReportProblem: () => _openReportIssueSheet(context, currentKeypoint),
        ),
        isLoading: isLoading,
        body: KeypointCardShell(
          bodyFactory: _bodyFactory,
          onAnswerChecked: _handleAnswerChecked,
        ),
      ),
    );
  }

  Future<void> _syncAudioKeypoint(KeypointEntity keypoint) async {
    // The listening chain has already walked the player into this keypoint (its
    // merged file is mid-sentence right now) and this sync is the APP catching
    // up — `ListenChainController` switched `CourseLessonCubit` onto it. Adopt
    // the entity and stop: `configure` would reset the player and reload the
    // very source that is playing, which is the boundary hiccup the queue exists
    // to avoid, and `enterAudioMode` would restart the keypoint from the top.
    //
    // Strictly the QUEUE-hopped keypoint, never merely "the keypoint playing":
    // an ordinary entry starts on the roadmap stub's legacy file and gets the
    // merged one as a same-keypoint refresh, which must reach `configure` (see
    // [LessonAudioCubit.isQueueHoppedKeypoint]).
    if (_lessonAudioCubit.isQueueHoppedKeypoint(keypoint.id)) {
      _lessonAudioCubit.adoptQueuedKeypoint(keypoint);
      await _lessonAudioCubit.setSpeed(AppDI.injector.get<KeypointDisplayCubit>().state.readingSpeed);
      _audioSyncedKeypointId = keypoint.id;
      _hasSyncedFirstKeypoint = true;
      return;
    }

    await _lessonAudioCubit.configure(keypoint);

    // TEMP-DEBUG(mute): remove with [MuteDbg] once first-keypoint autoplay is
    // confirmed settled.

    if (!keypoint.hasUsableAudio) return;

    await _lessonAudioCubit.setSpeed(AppDI.injector.get<KeypointDisplayCubit>().state.readingSpeed);

    // The sync listener fires on entity INEQUALITY, and the keypoint entity
    // refreshes mid-run (progress write on completion, lesson refetch) without
    // the keypoint actually changing. A re-sync over a RUNNING (or
    // user-silenced) session must stop HERE: falling through to enterAudioMode
    // wiped the reader's pinned mute and restarted narration on a screen they
    // had silenced — invisibly when the recap gate's leak guard swallowed the
    // sound, so the very next flip tap talked ("chủ động tắt thì tap card
    // cuối tự bật tiếng", 2026-08-09 [MuteDbg]).
    //
    // A re-sync with NO session running is the opposite case: the entry's own
    // autoplay never materialized (the deck's cue seek can interrupt the first
    // load, which resets the session), and this refresh is the retry that used
    // to rescue it — a hard id-gate here left a directly-opened keypoint
    // silent ("bấm trực tiếp vào 1 keypoint thì không tự động bật audio",
    // 2026-08-09). configure()/setSpeed above always run: a refresh may carry
    // a new dub.
    final audioState = _lessonAudioCubit.state;
    if (keypoint.id == _audioSyncedKeypointId && (audioState.hasStartedSession || _lessonAudioCubit.pausedByUser)) {
      return;
    }
    _audioSyncedKeypointId = keypoint.id;

    final isFirstKeypointSynced = !_hasSyncedFirstKeypoint;
    _hasSyncedFirstKeypoint = true;
    // A live "đang nghe dở" bookmark opens the merged file at that exact
    // second (deck follows in [_applyListenResume] once items land) and is a
    // listening intent in itself, so it also wins the autoplay decision.
    final resume = ListenResumeCubit.instanceOrNull?.recordFor(keypoint.id);
    // Every keypoint AFTER the first one always autoplays — narration
    // following the reader is this screen's standing behavior. The FIRST
    // keypoint's autoplay is gated on the route's entry intent so internal
    // navigations that don't represent "starting a fresh keypoint" (e.g.
    // `LessonCubit.reviewDone`'s bare re-entry) don't surprise the user with
    // sound.
    if (!isFirstKeypointSynced || widget.autoplayOnEntry || resume != null) {
      await _lessonAudioCubit.enterAudioMode(
        startAt: resume == null ? null : Duration(milliseconds: resume.positionMs),
      );
    }
  }

  /// Second half of resume: land the deck on the card the bookmarked second
  /// belongs to. The live edge is fast-forwarded for real (jump APIs) — the
  /// listener genuinely heard their way here, so finishing the keypoint from
  /// here must still write completion exactly as an unbroken session would.
  void _applyListenResume(LessonState lessonState) {
    final keypoint = context.read<CourseLessonCubit>().state.resolvedCurrentKeypoint;
    if (keypoint.id.isEmpty || _resumeAppliedForKeypoint == keypoint.id) return;
    _resumeAppliedForKeypoint = keypoint.id;

    final resume = ListenResumeCubit.instanceOrNull?.recordFor(keypoint.id);
    final timeline = _lessonAudioCubit.timeline;
    if (resume == null || timeline == null) return;

    final cue = timeline.cueAt(timeline.cueIndexAtMs(resume.positionMs));
    if (cue == null) return;

    final items = lessonState.pageData.items;
    final itemIndex = items.indexWhere((item) => item.id == cue.learningItemId);
    if (itemIndex < 0) return;

    final keypointCardCubit = context.read<KeypointCardCubit>();
    void applyJump() {
      _lessonCubit.jumpToItem(itemIndex);
      _lessonCubit.setCurrentLearningItem(items[itemIndex]);
      AppDI.injector.get<TheoryCubit>().jumpToDocument(cue.documentIndex);
      keypointCardCubit.jumpToCard(
        learningItemId: cue.learningItemId,
        documentIndex: cue.documentIndex,
      );
    }

    applyJump();

    // The entry flow (`loadAllLearningItems.onSuccess`) fetches the first
    // item's DETAIL asynchronously and, on landing, resets TheoryCubit to
    // document 0 of the first item — arriving after this jump it clobbers the
    // restored position (live edge snaps back, the deck yanks the view). Watch
    // for that one reset and re-assert once; the window is short-lived so an
    // ordinary user navigation can never re-trigger a stale jump.
    unawaited(_resumeGuard?.cancel());
    var reasserted = false;
    _resumeGuard = AppDI.injector.get<TheoryCubit>().stream.listen((theoryState) {
      if (reasserted) return;
      final onResumeSpot = theoryState.currentLearningItem.id == cue.learningItemId && theoryState.currentDocumentIndex == cue.documentIndex;
      if (onResumeSpot) return;
      // The clobber lands as a RESET (document 0) — anything else in this
      // window is the reader or the voice moving on, never ours to undo.
      if (theoryState.currentDocumentIndex != 0) return;
      reasserted = true;
      unawaited(_resumeGuard?.cancel());
      _resumeGuard = null;
      applyJump();
    });
    Future.delayed(const Duration(seconds: 4), () {
      unawaited(_resumeGuard?.cancel());
      _resumeGuard = null;
    });
  }

  void _openReportIssueSheet(BuildContext context, KeypointEntity keypoint) {
    final lessonId = context.read<CourseLessonCubit>().state.selectedLesson.id;
    ReportIssueSheet.show(
      context,
      lessonId: lessonId,
      keypointId: keypoint.id,
      keypointTitle: keypoint.title.text,
      keypointImage: keypoint.image,
    );
  }

  void _handleAnswerChecked(bool isCorrect) {
    debugPrint('Answer is correct: $isCorrect');
    final lessonState = context.read<LessonCubit>().state;
    if (lessonState.currentLearningItem.type != LearningItemType.exercise) return;
    isCorrect ? AppHaptic.success() : AppHaptic.error();
    context.read<LessonCubit>().markPendingAdvance();
  }

  /// Bookmark a GENERATED lesson as the reader moves through it.
  ///
  /// A no-op for catalogue content, which records progress server-side through
  /// its own endpoints — this is the one thing a generated lesson has to do for
  /// itself, because it lives in a collection those endpoints know nothing
  /// about. Fire-and-forget by design: losing the write costs a bookmark.
  void _saveImportedProgress(int cardIndex) {
    final lesson = context.read<CourseLessonCubit>().state.selectedLesson;
    if (!lesson.isImported) return;

    final keypointId = context.read<CourseLessonCubit>().state.currentKeypointId;
    final keypointIndex = UserLessonCourseMapper.keypointIndexOf(keypointId);
    if (keypointIndex < 0) return;

    AppDI.injector.get<UserLessonCubit>().saveProgress(
      lessonId: UserLessonCourseMapper.lessonIdOf(keypointId),
      keypointIndex: keypointIndex,
      sectionIndex: cardIndex,
    );
  }

  void _trackCurrentLearningItemScroll() {
    _trackingDelegate.trackCurrentLearningItemScroll(
      lessonState: _lessonCubit.state,
      shouldTrackScroll: (key) {
        if (key == _lastTrackedScrollKey) return false;
        _lastTrackedScrollKey = key;
        return true;
      },
    );
  }
}
