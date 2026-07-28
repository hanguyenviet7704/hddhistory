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
  /// Applies reading-speed changes to the player. The speed control now lives
  /// as an inline stepper inside [KeypointSettingsSheet], which is a modal
  /// route and therefore sits OUTSIDE this page's provider scope — it can only
  /// write the persisted [KeypointDisplayCubit] value, so the page listens
  /// here and pushes it into the route-scoped [LessonAudioCubit].
  StreamSubscription<KeypointDisplayState>? _readingSpeedSubscription;
  bool _hasSyncedFirstKeypoint = false;
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
    _reviewBodyBuilder = const LessonReviewBodyBuilder();
    _bodyFactory = LessonBodyFactory(
      onAnswerChecked: _handleAnswerChecked,
      onContinueUnsupported: () => AppDI.injector.get<ExerciseCubit>().nextQuestion(),
      reviewBodyBuilder: _reviewBodyBuilder,
    );
    _trackingDelegate = const LessonTrackingDelegate();

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
    unawaited(_readingSpeedSubscription?.cancel());
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
          listener: (context, state) => _trackCurrentLearningItemScroll(),
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
    await _lessonAudioCubit.configure(keypoint);

    if (!keypoint.hasUsableAudio) return;

    await _lessonAudioCubit.setSpeed(AppDI.injector.get<KeypointDisplayCubit>().state.readingSpeed);

    final isFirstKeypointSynced = !_hasSyncedFirstKeypoint;
    _hasSyncedFirstKeypoint = true;
    // Every keypoint AFTER the first one always autoplays — narration
    // following the reader is this screen's standing behavior. The FIRST
    // keypoint's autoplay is gated on the route's entry intent so internal
    // navigations that don't represent "starting a fresh keypoint" (e.g.
    // `LessonCubit.reviewDone`'s bare re-entry) don't surprise the user with
    // sound.
    if (!isFirstKeypointSynced || widget.autoplayOnEntry) {
      await _lessonAudioCubit.enterAudioMode();
    }
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
