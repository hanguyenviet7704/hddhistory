part of '../../video_lesson.dart';

enum VideoLessonNotesStatus { initial, loading, success, failure, loadingMore }

enum VideoLessonCrudStatus { idle, loading, success, failure }

enum VideoLessonNotesMode { list, editor }

enum VideoLessonQuestionActionMode { check, continueWatching }

@freezed
abstract class VideoLessonQuestionPrompt with _$VideoLessonQuestionPrompt {
  const factory VideoLessonQuestionPrompt({
    @Default('') String key,
    @Default(0) int order,
    @Default(0) int atSecond,
    @Default(QuestionEntity()) QuestionEntity question,
  }) = _VideoLessonQuestionPrompt;

  factory VideoLessonQuestionPrompt.fromJson(Map<String, dynamic> json) => _$VideoLessonQuestionPromptFromJson(json);
}

@freezed
abstract class VideoLessonQuestionResult with _$VideoLessonQuestionResult {
  const factory VideoLessonQuestionResult({
    @Default('') String key,
    @Default(0) int questionId,
    @Default(0) int atSecond,
    @Default(false) bool isCorrect,
    @Default(true) bool isSupported,
    @Default(-1) int selectedAnswerIndex,
    @Default({}) Set<int> selectedAnswerIndices,
    String? noCorrectDocumentGroupId,
  }) = _VideoLessonQuestionResult;

  factory VideoLessonQuestionResult.fromJson(Map<String, dynamic> json) => _$VideoLessonQuestionResultFromJson(json);
}
