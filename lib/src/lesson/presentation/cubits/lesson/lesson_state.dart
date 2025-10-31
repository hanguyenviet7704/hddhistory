part of '../../../lesson.dart';

enum LessonStatus { initial, loading, success, failure }

@freezed
abstract class LessonState with _$LessonState {
  const factory LessonState({
    @Default(LessonStatus.initial) LessonStatus status,
    @Default(BasePageBreak<LearningItemEntity>()) BasePageBreak<LearningItemEntity> pageData,
    @Default(0) int currentLearningItemIndex,
    @Default(0) int currentLessonIndex,
    @Default([]) List<QuestionEntity> subQuestions,
    @Default(-1) int currentSubQuestionIndex,
    String? errorMessage,
  }) = _LessonState;

  factory LessonState.initial() => LessonState();

  factory LessonState.fromJson(Map<String, dynamic> json) => _$LessonStateFromJson(json);
}

extension LessonStateExtension on LessonState {
  LearningItemEntity get currentLearningItem {
    return pageData.items.elementAtOrDefault(currentLearningItemIndex, defaultValue: LearningItemEntity());
  }

  TagEntity get currentTag {
    switch (currentLearningItem.type) {
      case LearningItemType.theory:
        return currentLearningItem.documents.elementAtOrDefault(currentLessonIndex, defaultValue: DocumentEntity()).tag;
      case LearningItemType.exercise:
        return currentLearningItem.questions.elementAtOrDefault(currentLessonIndex, defaultValue: QuestionEntity()).tag;
    }
  }

  String get currentLessonSpeechBubble {
    return switch (currentLearningItem.type) {
      LearningItemType.theory => currentLearningItem.documents.elementAtOrDefault(currentLessonIndex, defaultValue: DocumentEntity()).speechBubble,
      LearningItemType.exercise => currentLearningItem.questions.elementAtOrDefault(currentLessonIndex, defaultValue: QuestionEntity()).speechBubble,
    };
  }

  QuestionEntity get currentSubQuestion {
    return subQuestions.elementAtOrDefault(currentSubQuestionIndex, defaultValue: QuestionEntity());
  }

  int get totalLessonInAllItems {
    return pageData.items.fold(0, (sum, item) => sum + item.documents.length);
  }

  double get progress {
    return currentLessonIndex / totalLessonInAllItems;
  }
}
