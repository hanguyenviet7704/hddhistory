part of '../../video_lesson.dart';

@lazySingleton
class VideoLessonCubit extends Cubit<VideoLessonState> {
  static const _defaultInitializationTimeout = Duration(seconds: 12);
  static const _initializationTimeoutMessage = 'Video lesson is taking too long to load. Please try again.';

  VideoLessonCubit(
    this._getCourseLessonUseCase,
    this._getLearningItemUseCase,
    this._getAllUserVideoLessonNotesUseCase,
    this._createUserVideoLessonNoteUseCase,
    this._updateUserVideoLessonNoteUseCase,
    this._deleteUserVideoLessonNoteUseCase,
    this._updateUserProgressLessonUseCase,
    this._userCubit,
    this._courseRoadmapCubit,
  ) : super(VideoLessonState.initial());

  final GetCourseLessonUseCase _getCourseLessonUseCase;
  final GetVideoLearningItemUseCase _getLearningItemUseCase;
  final GetAllUserVideoLessonNotesUseCase _getAllUserVideoLessonNotesUseCase;
  final CreateUserVideoLessonNoteUseCase _createUserVideoLessonNoteUseCase;
  final UpdateUserVideoLessonNoteUseCase _updateUserVideoLessonNoteUseCase;
  final DeleteUserVideoLessonNoteUseCase _deleteUserVideoLessonNoteUseCase;
  final UpdateUserProgressLessonUseCase _updateUserProgressLessonUseCase;
  final UserCubit _userCubit;
  final CourseRoadmapCubit _courseRoadmapCubit;
  Duration _initializationTimeout = _defaultInitializationTimeout;

  @visibleForTesting
  void overrideInitializationTimeout(Duration timeout) {
    _initializationTimeout = timeout;
  }

  void reset() => emit(VideoLessonState.initial());

  Future<void> initialize({
    required String courseId,
    required String nodeId,
    required String lessonId,
  }) async {
    emit(
      VideoLessonState.initial().copyWith(
        courseId: courseId,
        nodeId: nodeId,
        lessonId: lessonId,
        loadStatus: VideoLessonLoadStatus.loading,
      ),
    );

    try {
      final lessonResult = await _runInitializationTask(_getCourseLessonUseCase(lessonId));
      final lesson = lessonResult.fold<LessonEntity?>(
        (error) {
          _emitInitializationFailure(error: error);
          return null;
        },
        (lesson) => lesson,
      );
      if (lesson == null) return;

      final learningItemResult = await _runInitializationTask(
        _getLearningItemUseCase(lesson.learningItemId),
      );
      learningItemResult.fold(
        (error) => _emitInitializationFailure(error: error, lesson: lesson),
        (learningItem) {
          emit(
            state.copyWith(
              loadStatus: lesson.video.url.trim().isEmpty ? VideoLessonLoadStatus.unavailable : VideoLessonLoadStatus.success,
              lesson: lesson,
              learningItem: learningItem,
            ),
          );
        },
      );
    } catch (error, stackTrace) {
      AppService.instance.appTrackingService.trackError(
        error,
        errorType: 'VideoLessonCubit.initialize',
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          loadStatus: VideoLessonLoadStatus.failure,
          errorMessage: _initializationTimeoutMessage,
        ),
      );
    }
  }

  void updatePlaybackProgress({
    required Duration position,
    required Duration duration,
  }) {
    final nextPosition = position.inSeconds.clamp(0, duration.inSeconds);
    final nextDuration = duration.inSeconds.clamp(0, 359999);
    if (state.positionSeconds == nextPosition && state.durationSeconds == nextDuration) return;

    emit(
      state.copyWith(
        positionSeconds: nextPosition,
        durationSeconds: nextDuration,
      ),
    );
  }

  void setPlaybackState({
    required bool isPlaying,
    bool? controlsVisible,
  }) {
    emit(
      state.copyWith(
        isPlaying: isPlaying,
        controlsVisible: controlsVisible ?? state.controlsVisible,
      ),
    );
  }

  void setControlsVisible(bool visible) {
    if (state.controlsVisible == visible) return;
    emit(state.copyWith(controlsVisible: visible));
  }

  void toggleControlsVisibility() {
    if (!state.isPlaying || state.hasBlockingOverlay) return;
    emit(state.copyWith(controlsVisible: !state.controlsVisible));
  }

  bool openNotes({required bool wasPlayingBeforeOverlay}) {
    if (!state.canOpenNotesOrSummary) return false;
    emit(
      state.copyWith(
        activeOverlay: VideoLessonOverlay.notes,
        notesMode: VideoLessonNotesMode.list,
        wasPlayingBeforeOverlay: wasPlayingBeforeOverlay,
        notesViewTracked: false,
        notesActionErrorMessage: null,
      ),
    );
    if (state.notesStatus == VideoLessonNotesStatus.initial) {
      unawaited(loadNotes());
    }
    return true;
  }

  void closeNotes() {
    emit(
      state.copyWith(
        activeOverlay: VideoLessonOverlay.none,
        notesMode: VideoLessonNotesMode.list,
        wasPlayingBeforeOverlay: false,
        notesViewTracked: false,
        noteSaveStatus: VideoLessonCrudStatus.idle,
        noteDeleteStatus: VideoLessonCrudStatus.idle,
        notesActionErrorMessage: null,
      ),
    );
  }

  bool openSummary({required bool wasPlayingBeforeOverlay}) {
    if (!state.canOpenNotesOrSummary) return false;
    emit(
      state.copyWith(
        activeOverlay: VideoLessonOverlay.summary,
        wasPlayingBeforeOverlay: wasPlayingBeforeOverlay,
        summaryViewTracked: false,
        summaryScrollTracked: false,
      ),
    );
    return true;
  }

  void closeSummary() {
    emit(
      state.copyWith(
        activeOverlay: VideoLessonOverlay.none,
        wasPlayingBeforeOverlay: false,
        summaryViewTracked: false,
        summaryScrollTracked: false,
      ),
    );
  }

  Future<void> loadNotes({bool showLoading = true}) async {
    final currentState = state;
    if (currentState.notesStatus == VideoLessonNotesStatus.loading) return;

    emit(
      currentState.copyWith(
        notesStatus: showLoading ? VideoLessonNotesStatus.loading : VideoLessonNotesStatus.success,
        notesCurrentPage: 1,
        notesReachedEnd: false,
        notesErrorMessage: null,
        notesLoadMoreErrorMessage: null,
      ),
    );

    final result = await _getAllUserVideoLessonNotesUseCase(_notesRequest(page: 1)).run();
    result.fold(
      (error) {
        emit(
          state.copyWith(
            notesStatus: VideoLessonNotesStatus.failure,
            notesErrorMessage: error.displayMessage,
          ),
        );
      },
      (pageData) {
        emit(
          state.copyWith(
            notesStatus: VideoLessonNotesStatus.success,
            notesCurrentPage: pageData.currentPage == 0 ? 1 : pageData.currentPage,
            notesReachedEnd: pageData.isLastPage || pageData.items.isEmpty,
            notes: _dedupeNotes(pageData.items),
            notesErrorMessage: null,
            notesLoadMoreErrorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> loadMoreNotes() async {
    final currentState = state;
    if (currentState.notesLoadMoreStatus == VideoLessonNotesStatus.loadingMore || currentState.notesStatus != VideoLessonNotesStatus.success || currentState.notesReachedEnd) {
      return;
    }

    emit(
      currentState.copyWith(
        notesLoadMoreStatus: VideoLessonNotesStatus.loadingMore,
        notesLoadMoreErrorMessage: null,
      ),
    );

    final nextPage = currentState.notesCurrentPage + 1;
    final result = await _getAllUserVideoLessonNotesUseCase(_notesRequest(page: nextPage)).run();
    result.fold(
      (error) {
        emit(
          state.copyWith(
            notesLoadMoreStatus: VideoLessonNotesStatus.failure,
            notesLoadMoreErrorMessage: error.displayMessage,
          ),
        );
      },
      (pageData) {
        emit(
          state.copyWith(
            notesLoadMoreStatus: VideoLessonNotesStatus.success,
            notesCurrentPage: pageData.currentPage == 0 ? nextPage : pageData.currentPage,
            notesReachedEnd: pageData.isLastPage || pageData.items.isEmpty,
            notes: _dedupeNotes([...state.notes, ...pageData.items]),
            notesLoadMoreErrorMessage: null,
          ),
        );
      },
    );
  }

  void openCreateNote() {
    emit(
      state.copyWith(
        notesMode: VideoLessonNotesMode.editor,
        editingNote: null,
        noteDraft: '',
        noteSaveStatus: VideoLessonCrudStatus.idle,
        noteDeleteStatus: VideoLessonCrudStatus.idle,
        notesActionErrorMessage: null,
      ),
    );
  }

  void openEditNote(UserVideoLessonNoteEntity note) {
    emit(
      state.copyWith(
        notesMode: VideoLessonNotesMode.editor,
        editingNote: note,
        noteDraft: note.content,
        noteSaveStatus: VideoLessonCrudStatus.idle,
        noteDeleteStatus: VideoLessonCrudStatus.idle,
        notesActionErrorMessage: null,
      ),
    );
  }

  void backToNotesList() {
    emit(
      state.copyWith(
        notesMode: VideoLessonNotesMode.list,
        noteSaveStatus: VideoLessonCrudStatus.idle,
        noteDeleteStatus: VideoLessonCrudStatus.idle,
        notesActionErrorMessage: null,
      ),
    );
  }

  void updateNoteDraft(String value) {
    if (state.noteDraft == value) return;
    emit(state.copyWith(noteDraft: value));
  }

  void clearNotesActionError() {
    emit(state.copyWith(notesActionErrorMessage: null));
  }

  Future<void> saveNote() async {
    final draft = videoLessonCanonicalizeNoteContent(state.noteDraft);
    if (videoLessonNoteContentIsBlank(draft) || state.noteSaveStatus == VideoLessonCrudStatus.loading) return;

    emit(
      state.copyWith(
        noteSaveStatus: VideoLessonCrudStatus.loading,
        notesActionErrorMessage: null,
      ),
    );

    final editingNote = state.editingNote;
    final payload = UserVideoLessonNoteEntity(
      id: editingNote?.id ?? '',
      userId: _userCubit.state.user.id,
      courseId: state.courseId,
      nodeId: state.nodeId,
      lessonId: state.lessonId,
      content: draft,
      atSecond: editingNote?.atSecond ?? state.positionSeconds,
    );

    final result = editingNote == null ? await _createUserVideoLessonNoteUseCase(payload).run() : await _updateUserVideoLessonNoteUseCase(payload).run();

    await result.fold(
      (error) async {
        emit(
          state.copyWith(
            noteSaveStatus: VideoLessonCrudStatus.failure,
            notesActionErrorMessage: error.displayMessage,
          ),
        );
      },
      (_) async {
        emit(
          state.copyWith(
            noteSaveStatus: VideoLessonCrudStatus.success,
            noteDraft: '',
            editingNote: null,
            notesMode: VideoLessonNotesMode.list,
          ),
        );
        await loadNotes(showLoading: false);
      },
    );
  }

  Future<void> deleteNote(UserVideoLessonNoteEntity note) async {
    if (state.noteDeleteStatus == VideoLessonCrudStatus.loading) return;

    emit(
      state.copyWith(
        noteDeleteStatus: VideoLessonCrudStatus.loading,
        notesActionErrorMessage: null,
      ),
    );

    final result = await _deleteUserVideoLessonNoteUseCase(note).run();
    await result.fold(
      (error) async {
        emit(
          state.copyWith(
            noteDeleteStatus: VideoLessonCrudStatus.failure,
            notesActionErrorMessage: error.displayMessage,
          ),
        );
      },
      (_) async {
        emit(
          state.copyWith(
            noteDeleteStatus: VideoLessonCrudStatus.success,
            notesMode: VideoLessonNotesMode.list,
            editingNote: state.editingNote?.id == note.id ? null : state.editingNote,
            noteDraft: state.editingNote?.id == note.id ? '' : state.noteDraft,
            notes: state.notes.where((item) => item.id != note.id).toList(),
          ),
        );
        if (state.notes.isEmpty) {
          await loadNotes(showLoading: false);
        }
      },
    );
  }

  bool maybeTriggerZeroSecondQuestion() {
    if (state.hasBlockingOverlay) return false;
    final zeroSecondPrompts = _pendingPrompts().where((prompt) => prompt.atSecond == 0).toList();
    if (zeroSecondPrompts.isEmpty) return false;
    _openQuestionSequence(
      zeroSecondPrompts,
      resumeAfterQueue: true,
      pendingEndAfterQueue: false,
    );
    return true;
  }

  bool processPlaybackAdvance({
    required int fromSecond,
    required int toSecond,
  }) {
    if (state.hasBlockingOverlay || toSecond <= fromSecond) return false;
    final crossedPrompts = _pendingPrompts().where((prompt) => prompt.atSecond > 0 && prompt.atSecond > fromSecond && prompt.atSecond <= toSecond).toList();
    if (crossedPrompts.isEmpty) return false;
    _openQuestionSequence(
      crossedPrompts,
      resumeAfterQueue: true,
      pendingEndAfterQueue: false,
    );
    return true;
  }

  void handleBackwardSeek({
    required int targetSecond,
    required bool wasPlayingBeforeSeek,
  }) {
    final rearmedKeys = _allPrompts().where((prompt) => prompt.atSecond >= targetSecond).map((prompt) => prompt.key).toSet();
    final nextResults = Map<String, VideoLessonQuestionResult>.from(state.questionResults)..removeWhere((key, value) => rearmedKeys.contains(key));

    emit(
      state.copyWith(
        questionResults: nextResults,
        skippedQuestionQueue: const [],
        currentQuestionPrompt: null,
        currentQuestionResult: null,
        currentSelectedAnswerIndex: -1,
        currentSelectedAnswerIndices: const {},
        resumePlaybackAfterQuestionQueue: wasPlayingBeforeSeek,
        pendingEndAfterQuestionQueue: false,
        wasPlayingBeforeSeek: wasPlayingBeforeSeek,
        activeOverlay: state.activeOverlay == VideoLessonOverlay.end ? VideoLessonOverlay.none : state.activeOverlay,
      ),
    );
  }

  bool handleForwardSeek({
    required int fromSecond,
    required int toSecond,
    required bool wasPlayingBeforeSeek,
  }) {
    final skippedPrompts = _pendingPrompts().where((prompt) => prompt.atSecond > fromSecond && prompt.atSecond <= toSecond).toList();
    if (skippedPrompts.isNotEmpty) {
      _openQuestionSequence(
        skippedPrompts,
        resumeAfterQueue: wasPlayingBeforeSeek,
        pendingEndAfterQueue: state.durationSeconds > 0 && toSecond >= state.durationSeconds,
      );
      return true;
    }

    if (state.durationSeconds > 0 && toSecond >= state.durationSeconds) {
      showEndOverlay();
      return true;
    }
    return false;
  }

  void selectCurrentQuestionAnswer(int index) {
    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;

    if (state.currentQuestionIsMultipleChoice) {
      final selected = Set<int>.from(state.currentSelectedAnswerIndices);
      if (selected.contains(index)) {
        selected.remove(index);
      } else {
        selected.add(index);
      }
      emit(state.copyWith(currentSelectedAnswerIndices: selected));
      return;
    }

    emit(state.copyWith(currentSelectedAnswerIndex: index));
  }

  void submitCurrentQuestion() {
    final prompt = state.currentQuestionPrompt;
    final question = state.currentQuestion;
    if (prompt == null || question == null || !state.currentQuestionCanSubmit) return;

    final noCorrectDocumentGroupId = state.currentQuestionIsNoCorrectSingleChoice
        ? resolveNoCorrectAnswerDocumentGroup(
            question: question,
            selectedAnswerIndex: state.currentSelectedAnswerIndex,
          )?.groupId
        : null;

    final isCorrect = state.currentQuestionIsSupported
        ? resolveChoiceCheckResult(
            isMultipleChoice: state.currentQuestionIsMultipleChoice,
            isNoCorrectSingleChoice: state.currentQuestionIsNoCorrectSingleChoice,
            selectedAnswerIndex: state.currentSelectedAnswerIndex,
            selectedAnswersIndices: state.currentSelectedAnswerIndices,
            correctOptionsIndices: _correctOptionIndices(question),
          )
        : true;

    final result = VideoLessonQuestionResult(
      key: prompt.key,
      questionId: question.id,
      atSecond: prompt.atSecond,
      isCorrect: isCorrect,
      isSupported: state.currentQuestionIsSupported,
      selectedAnswerIndex: state.currentSelectedAnswerIndex,
      selectedAnswerIndices: state.currentSelectedAnswerIndices,
      noCorrectDocumentGroupId: noCorrectDocumentGroupId,
    );

    emit(
      state.copyWith(
        activeOverlay: VideoLessonOverlay.questionResult,
        currentQuestionResult: result,
        questionResults: {
          ...state.questionResults,
          prompt.key: result,
        },
        questionResultViewTracked: false,
      ),
    );
  }

  bool continueAfterQuestion() {
    final queuedPrompts = state.skippedQuestionQueue;
    if (queuedPrompts.isNotEmpty) {
      final nextPrompt = queuedPrompts.first;
      emit(
        state.copyWith(
          activeOverlay: VideoLessonOverlay.question,
          currentQuestionPrompt: nextPrompt,
          currentQuestionResult: null,
          skippedQuestionQueue: queuedPrompts.skip(1).toList(),
          currentSelectedAnswerIndex: -1,
          currentSelectedAnswerIndices: const {},
          questionViewTracked: false,
          questionResultViewTracked: false,
        ),
      );
      return false;
    }

    if (state.pendingEndAfterQuestionQueue) {
      showEndOverlay();
      return false;
    }

    final shouldResume = state.resumePlaybackAfterQuestionQueue;
    emit(
      state.copyWith(
        activeOverlay: VideoLessonOverlay.none,
        currentQuestionPrompt: null,
        currentQuestionResult: null,
        currentSelectedAnswerIndex: -1,
        currentSelectedAnswerIndices: const {},
        resumePlaybackAfterQuestionQueue: false,
        pendingEndAfterQuestionQueue: false,
        questionViewTracked: false,
        questionResultViewTracked: false,
      ),
    );
    return shouldResume;
  }

  void showEndOverlay() {
    if (state.isEndVisible) return;
    emit(
      state.copyWith(
        activeOverlay: VideoLessonOverlay.end,
        currentQuestionPrompt: null,
        currentQuestionResult: null,
        currentSelectedAnswerIndex: -1,
        currentSelectedAnswerIndices: const {},
        isPlaying: false,
        controlsVisible: true,
        completionStatus: VideoLessonCompletionStatus.idle,
        completionErrorMessage: null,
        resumePlaybackAfterQuestionQueue: false,
        pendingEndAfterQuestionQueue: false,
      ),
    );
  }

  void markScreenViewTracked() => emit(state.copyWith(screenViewTracked: true));

  void markEndViewTracked() => emit(state.copyWith(endViewTracked: true));

  void markNotesViewTracked() => emit(state.copyWith(notesViewTracked: true));

  void markSummaryViewTracked() => emit(state.copyWith(summaryViewTracked: true));

  void markSummaryScrollTracked() => emit(state.copyWith(summaryScrollTracked: true));

  void markQuestionViewTracked() => emit(state.copyWith(questionViewTracked: true));

  void markQuestionResultViewTracked() => emit(state.copyWith(questionResultViewTracked: true));

  void setLoadFailure(String errorMessage) {
    emit(
      state.copyWith(
        loadStatus: VideoLessonLoadStatus.failure,
        errorMessage: errorMessage,
      ),
    );
  }

  Future<void> completeLesson() async {
    if (state.completionStatus == VideoLessonCompletionStatus.loading) return;

    emit(
      state.copyWith(
        completionStatus: VideoLessonCompletionStatus.loading,
        completionErrorMessage: null,
      ),
    );

    final result = await _updateUserProgressLessonUseCase(
      UpdateUserProgressLessonParams(
        lessonId: state.lessonId,
        body: {
          'userId': _userCubit.state.user.id,
          'courseId': state.courseId,
          'averageScore': 0,
          'passed': true,
        },
      ),
    ).run();

    result.fold(
      (error) {
        emit(
          state.copyWith(
            completionStatus: VideoLessonCompletionStatus.failure,
            completionErrorMessage: error.displayMessage,
          ),
        );
      },
      (_) {
        _courseRoadmapCubit.loadRoadmap(courseId: state.courseId);
        HomeWidgetSyncTrigger.requestDebouncedSync(changedCourseId: state.courseId);
        emit(state.copyWith(completionStatus: VideoLessonCompletionStatus.success));
      },
    );
  }

  void clearSessionStateForExit() {
    emit(
      state.copyWith(
        activeOverlay: VideoLessonOverlay.none,
        notesMode: VideoLessonNotesMode.list,
        noteDraft: '',
        editingNote: null,
        currentQuestionPrompt: null,
        currentQuestionResult: null,
        questionResults: const {},
        skippedQuestionQueue: const [],
        currentSelectedAnswerIndex: -1,
        currentSelectedAnswerIndices: const {},
        resumePlaybackAfterQuestionQueue: false,
        pendingEndAfterQuestionQueue: false,
        wasPlayingBeforeOverlay: false,
        wasPlayingBeforeSeek: false,
      ),
    );
  }

  PageBreakRequest<VideoLessonNoteFilterEntity> _notesRequest({required int page}) {
    return PageBreakRequest<VideoLessonNoteFilterEntity>(
      page: page,
      limit: 10,
      orderBy: 'createdAt',
      order: PageBreakOrder.desc,
      filter: state.noteFilter,
    );
  }

  List<UserVideoLessonNoteEntity> _dedupeNotes(List<UserVideoLessonNoteEntity> items) {
    final seenIds = <String>{};
    final results = <UserVideoLessonNoteEntity>[];
    for (final item in items) {
      if (item.id.isEmpty || seenIds.add(item.id)) {
        results.add(item);
      }
    }
    return results;
  }

  void _openQuestionSequence(
    List<VideoLessonQuestionPrompt> prompts, {
    required bool resumeAfterQueue,
    required bool pendingEndAfterQueue,
  }) {
    final nextPrompt = prompts.first;
    emit(
      state.copyWith(
        activeOverlay: VideoLessonOverlay.question,
        currentQuestionPrompt: nextPrompt,
        currentQuestionResult: null,
        skippedQuestionQueue: prompts.skip(1).toList(),
        currentSelectedAnswerIndex: -1,
        currentSelectedAnswerIndices: const {},
        questionViewTracked: false,
        questionResultViewTracked: false,
        resumePlaybackAfterQuestionQueue: resumeAfterQueue,
        pendingEndAfterQuestionQueue: pendingEndAfterQueue,
      ),
    );
  }

  List<VideoLessonQuestionPrompt> _allPrompts() {
    final prompts = <VideoLessonQuestionPrompt>[];
    for (final entry in state.learningItem.videoQuestions.asMap().entries) {
      final key = _questionKey(entry.key, entry.value);
      prompts.add(
        VideoLessonQuestionPrompt(
          key: key,
          order: entry.key,
          atSecond: entry.value.atSecond,
          question: entry.value.exercise,
        ),
      );
    }
    prompts.sort((a, b) {
      final timeCompare = a.atSecond.compareTo(b.atSecond);
      if (timeCompare != 0) return timeCompare;
      return a.order.compareTo(b.order);
    });
    return prompts;
  }

  List<VideoLessonQuestionPrompt> _pendingPrompts() {
    final completedKeys = state.questionResults.keys.toSet();
    final queuedKeys = state.skippedQuestionQueue.map((prompt) => prompt.key).toSet();
    final currentKey = state.currentQuestionPrompt?.key;

    return _allPrompts().where((prompt) {
      if (!_isPromptValid(prompt)) return false;
      if (completedKeys.contains(prompt.key)) return false;
      if (queuedKeys.contains(prompt.key)) return false;
      if (currentKey == prompt.key) return false;
      return true;
    }).toList();
  }

  bool _isPromptValid(VideoLessonQuestionPrompt prompt) {
    if (prompt.atSecond < 0) return false;
    if (state.durationSeconds > 0 && prompt.atSecond > state.durationSeconds) return false;
    return true;
  }

  String _questionKey(int order, VideoQuestionEntity question) => '${question.exercise.id}_${question.atSecond}_$order';

  Set<int> _correctOptionIndices(QuestionEntity question) {
    final options = questionRuntimeOptions(question);
    final indices = <int>{};
    for (int i = 0; i < options.length; i++) {
      if (options[i].isCorrect) indices.add(i);
    }
    if (question.typedPayload is QuestionSingleChoiceNoCorrectAnswerPayloadEntity && state.currentSelectedAnswerIndex >= 0) {
      return {state.currentSelectedAnswerIndex};
    }
    return indices;
  }

  Future<Either<AppException, T>> _runInitializationTask<T>(
    TaskEither<AppException, T> task,
  ) {
    return task.run().timeout(
      _initializationTimeout,
      onTimeout: () => left(
        const AppException.pending(_initializationTimeoutMessage),
      ),
    );
  }

  void _emitInitializationFailure({
    required AppException error,
    LessonEntity? lesson,
  }) {
    emit(
      state.copyWith(
        loadStatus: VideoLessonLoadStatus.failure,
        lesson: lesson ?? state.lesson,
        errorMessage: error is PendingException ? _initializationTimeoutMessage : error.displayMessage,
      ),
    );
  }
}
