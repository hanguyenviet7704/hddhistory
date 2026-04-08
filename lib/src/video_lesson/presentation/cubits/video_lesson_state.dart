part of '../../video_lesson.dart';

enum VideoLessonLoadStatus { initial, loading, success, failure, unavailable }

enum VideoLessonCompletionStatus { idle, loading, success, failure }

enum VideoLessonOverlay { none, notes, summary, question, questionResult, end }

@freezed
abstract class VideoLessonState with _$VideoLessonState {
  const factory VideoLessonState({
    @Default(VideoLessonLoadStatus.initial) VideoLessonLoadStatus loadStatus,
    @Default(VideoLessonCompletionStatus.idle) VideoLessonCompletionStatus completionStatus,
    @Default(VideoLessonOverlay.none) VideoLessonOverlay activeOverlay,
    @Default(VideoLessonNotesMode.list) VideoLessonNotesMode notesMode,
    @Default(VideoLessonNotesStatus.initial) VideoLessonNotesStatus notesStatus,
    @Default(VideoLessonNotesStatus.initial) VideoLessonNotesStatus notesLoadMoreStatus,
    @Default(VideoLessonCrudStatus.idle) VideoLessonCrudStatus noteSaveStatus,
    @Default(VideoLessonCrudStatus.idle) VideoLessonCrudStatus noteDeleteStatus,
    @Default('') String courseId,
    @Default('') String nodeId,
    @Default('') String lessonId,
    @Default(LessonEntity()) LessonEntity lesson,
    @Default(LearningItemEntity()) LearningItemEntity learningItem,
    String? errorMessage,
    String? completionErrorMessage,
    String? notesErrorMessage,
    String? notesLoadMoreErrorMessage,
    String? notesActionErrorMessage,
    @Default(0) int positionSeconds,
    @Default(0) int durationSeconds,
    @Default(false) bool isPlaying,
    @Default(true) bool controlsVisible,
    @Default(false) bool wasPlayingBeforeOverlay,
    @Default(false) bool wasPlayingBeforeSeek,
    @Default(false) bool resumePlaybackAfterQuestionQueue,
    @Default(false) bool pendingEndAfterQuestionQueue,
    @Default(false) bool screenViewTracked,
    @Default(false) bool endViewTracked,
    @Default(false) bool notesViewTracked,
    @Default(false) bool summaryViewTracked,
    @Default(false) bool summaryScrollTracked,
    @Default(false) bool questionViewTracked,
    @Default(false) bool questionResultViewTracked,
    @Default(1) int notesCurrentPage,
    @Default(false) bool notesReachedEnd,
    @Default([]) List<UserVideoLessonNoteEntity> notes,
    @Default('') String noteDraft,
    UserVideoLessonNoteEntity? editingNote,
    VideoLessonQuestionPrompt? currentQuestionPrompt,
    VideoLessonQuestionResult? currentQuestionResult,
    @Default({}) Map<String, VideoLessonQuestionResult> questionResults,
    @Default([]) List<VideoLessonQuestionPrompt> skippedQuestionQueue,
    @Default(-1) int currentSelectedAnswerIndex,
    @Default({}) Set<int> currentSelectedAnswerIndices,
  }) = _VideoLessonState;

  factory VideoLessonState.initial() => const VideoLessonState();

  factory VideoLessonState.fromJson(Map<String, dynamic> json) => _$VideoLessonStateFromJson(json);
}

extension VideoLessonStateX on VideoLessonState {
  bool get isReady => loadStatus == VideoLessonLoadStatus.success;

  bool get isLoading => loadStatus == VideoLessonLoadStatus.loading;

  bool get hasBlockingOverlay => activeOverlay != VideoLessonOverlay.none;

  bool get isEndVisible => activeOverlay == VideoLessonOverlay.end;

  bool get isNotesVisible => activeOverlay == VideoLessonOverlay.notes;

  bool get isSummaryVisible => activeOverlay == VideoLessonOverlay.summary;

  bool get isQuestionVisible => activeOverlay == VideoLessonOverlay.question;

  bool get isQuestionResultVisible => activeOverlay == VideoLessonOverlay.questionResult;

  bool get hasVideo => lesson.video.url.trim().isNotEmpty;

  bool get hasPendingSkippedQuestions => skippedQuestionQueue.isNotEmpty;

  bool get canOpenNotesOrSummary => !isPlaying && !hasPendingSkippedQuestions && !isQuestionVisible && !isQuestionResultVisible && !isEndVisible;

  Duration get position => Duration(seconds: positionSeconds);

  Duration get duration => Duration(seconds: durationSeconds);

  VideoLessonNoteFilterEntity get noteFilter => VideoLessonNoteFilterEntity(
    courseId: courseId,
    nodeId: nodeId,
    lessonId: lessonId,
  );

  bool get isEditingNote => editingNote != null;

  QuestionEntity? get currentQuestion => currentQuestionPrompt?.question;

  QuestionPayloadEntity? get currentQuestionPayload => currentQuestion?.typedPayload;

  bool get currentQuestionIsMultipleChoice => currentQuestionPayload is QuestionMultipleChoicePayloadEntity;

  bool get currentQuestionIsNoCorrectSingleChoice => currentQuestionPayload is QuestionSingleChoiceNoCorrectAnswerPayloadEntity;

  bool get currentQuestionIsSupported =>
      currentQuestionPayload is QuestionSingleChoicePayloadEntity ||
      currentQuestionPayload is QuestionMultipleChoicePayloadEntity ||
      currentQuestionPayload is QuestionSingleChoiceNoCorrectAnswerPayloadEntity;

  bool get currentQuestionCanSubmit {
    if (currentQuestion == null) return false;
    if (!currentQuestionIsSupported) return true;
    if (currentQuestionIsMultipleChoice) return currentSelectedAnswerIndices.isNotEmpty;
    return currentSelectedAnswerIndex >= 0;
  }

  List<OptionEntity> get currentQuestionOptions {
    final question = currentQuestion;
    if (question == null) return const [];
    return questionRuntimeOptions(question);
  }

  String get playbackLabel {
    final positionLabel = _formatPlaybackDuration(position);
    final durationLabel = _formatPlaybackDuration(duration);
    return '$positionLabel / $durationLabel';
  }
}

String _formatPlaybackDuration(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 359999);
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
