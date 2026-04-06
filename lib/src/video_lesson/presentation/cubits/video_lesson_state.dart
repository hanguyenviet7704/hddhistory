
part of '../../video_lesson.dart';

enum VideoLessonStatus { initial, loading, success, failure }

@freezed
abstract class VideoLessonState with _$VideoLessonState {
  const factory VideoLessonState({
    @Default(VideoLessonStatus.initial) VideoLessonStatus status,
    @Default(BasePageBreak<UserVideoLessonNoteEntity>()) BasePageBreak<UserVideoLessonNoteEntity> pageData,
    String? errorMessage,
  }) = _VideoLessonState;

  factory VideoLessonState.initial() => VideoLessonState();

  factory VideoLessonState.fromJson(Map<String, dynamic> json) => _$VideoLessonStateFromJson(json);
}

