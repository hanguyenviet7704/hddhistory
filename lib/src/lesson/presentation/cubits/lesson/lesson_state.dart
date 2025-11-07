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
      case LearningItemType.roleplay:
        return TagEntity();
    }
  }

  String get currentLessonSpeechBubble {
    return switch (currentLearningItem.type) {
      LearningItemType.theory => currentLearningItem.documents.elementAtOrDefault(currentLessonIndex, defaultValue: DocumentEntity()).speechBubble,
      LearningItemType.exercise => currentLearningItem.questions.elementAtOrDefault(currentLessonIndex, defaultValue: QuestionEntity()).speechBubble,
      LearningItemType.roleplay => '',
    };
  }

  int get totalLessonInAllItems {
    return pageData.items.fold(0, (sum, item) {
      if (item.isPlayingSubQuestions) return sum;
      switch (item.type) {
        case LearningItemType.theory:
          return sum + item.documents.length;
        case LearningItemType.exercise:
          return sum + item.questions.length;
        case LearningItemType.roleplay:
          return sum + item.documents.length; 
      }
    });
  }

  int get _doneProgress {
    return pageData.items.sublist(0, currentLearningItemIndex).fold(0, (sum, item) {
      if (item.isPlayingSubQuestions) return sum;
      switch (item.type) {
        case LearningItemType.theory:
          return sum + item.documents.length;
        case LearningItemType.exercise:
          return sum + item.questions.length;
        case LearningItemType.roleplay:
          return sum + item.documents.length;
      }
    });
  }

  double get progress {
    if (totalLessonInAllItems == 0) return 0;
    if (currentLearningItem.isPlayingSubQuestions) {
      if (currentLearningItem.questions.isEmpty) return 0;
      if (currentLessonIndex >= currentLearningItem.questions.length) return 1;
      return (currentLessonIndex + 1) / currentLearningItem.questions.length;
    }
    return (_doneProgress + currentLessonIndex + 1) / totalLessonInAllItems;
  }
}
