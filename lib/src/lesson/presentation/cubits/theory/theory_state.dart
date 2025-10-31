part of '../../../lesson.dart';

enum TheoryStatus { initial, loading, success, failure }

@freezed
abstract class TheoryState with _$TheoryState {
  const factory TheoryState({
    @Default(TheoryStatus.initial) TheoryStatus status,
    @Default(BasePageBreak<LearningItemEntity>()) BasePageBreak<LearningItemEntity> pageData,
    @Default(LearningItemEntity()) LearningItemEntity currentLearningItem,
    @Default(0) int currentDocumentIndex,
    @Default(false) bool hasChecked,
    @Default(false) bool isCorrect,
    @Default(false) bool showExplanation,
    String? errorMessage,
  }) = _TheoryState;

  factory TheoryState.initial() => TheoryState();

  factory TheoryState.fromJson(Map<String, dynamic> json) => _$TheoryStateFromJson(json);
}

extension TheoryStateExtension on TheoryState {
  DocumentEntity get currentDocument {
    return currentLearningItem.documents.elementAtOrDefault(currentDocumentIndex, defaultValue: DocumentEntity());
  }

  double get progress {
    if (currentLearningItem.documents.isEmpty) return 0;
    if (currentDocumentIndex >= currentLearningItem.documents.length) return 1;
    return (currentDocumentIndex + 1) / currentLearningItem.documents.length;
  }
}
