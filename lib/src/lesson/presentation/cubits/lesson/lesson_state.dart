part of '../../../lesson.dart';

enum LessonStatus { initial, loading, success, failure }

@freezed
abstract class LessonState with _$LessonState {
  const factory LessonState({
    @Default(LessonStatus.initial) LessonStatus status,
    @Default(BasePageBreak<LearningItemEntity>()) BasePageBreak<LearningItemEntity> pageData,
    @Default(0) int currentLearningItemIndex,
    String? errorMessage,
  }) = _LessonState;

  factory LessonState.initial() => LessonState();

  factory LessonState.fromJson(Map<String, dynamic> json) => _$LessonStateFromJson(json);
}

extension LessonStateExtension on LessonState {
  LearningItemEntity get currentLearningItem {
    return pageData.items.elementAtOrDefault(currentLearningItemIndex, defaultValue: LearningItemEntity());
  }
}