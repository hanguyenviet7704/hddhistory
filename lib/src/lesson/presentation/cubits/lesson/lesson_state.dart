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
      case LearningItemType.exercise || LearningItemType.roleplay:
        return currentLearningItem.questions.elementAtOrDefault(currentLessonIndex, defaultValue: QuestionEntity()).tag;
    }
  }

  String get currentLessonSpeechBubble {
    return switch (currentLearningItem.type) {
      LearningItemType.theory => currentLearningItem.documents.elementAtOrDefault(currentLessonIndex, defaultValue: DocumentEntity()).speechBubble,
      LearningItemType.exercise || LearningItemType.roleplay => currentLearningItem.questions.elementAtOrDefault(currentLessonIndex, defaultValue: QuestionEntity()).speechBubble,
    };
  }

  int get totalLessonInAllItems {
    return pageData.items.fold(0, (sum, item) {
      if (!item.isPlayingMainQuestions) {
        if(sum == 0) return item.questions.length;
        return sum;
      }

      switch (item.type) {
        case LearningItemType.theory:
          return sum + item.documents.length;
        case LearningItemType.exercise || LearningItemType.roleplay:
          return sum + item.questions.length;
      }
    });
  }

  int get _doneProgress {
    return pageData.items.sublist(0, currentLearningItemIndex).fold(0, (sum, item) {
      if (!item.isPlayingMainQuestions) return sum;
      switch (item.type) {
        case LearningItemType.theory:
          return sum + item.documents.length;
        case LearningItemType.exercise || LearningItemType.roleplay:
          return sum + item.questions.length;
      }
    });
  }

  double get progress {
    if (totalLessonInAllItems == 0) return 0;
    if (!currentLearningItem.isPlayingMainQuestions) {
      if (currentLearningItem.questions.isEmpty) return 0;
      if (currentLessonIndex >= currentLearningItem.questions.length) return 1;
      return (currentLessonIndex + 1) / currentLearningItem.questions.length;
    }
    return (_doneProgress + currentLessonIndex + 1) / totalLessonInAllItems;
  }
}
