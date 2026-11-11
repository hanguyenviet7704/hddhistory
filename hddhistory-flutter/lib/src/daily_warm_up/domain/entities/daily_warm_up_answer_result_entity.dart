part of '../../daily_warm_up.dart';

enum DailyWarmUpAnswerResultType { correct, incorrect, neutral, unsupported }

extension DailyWarmUpAnswerResultTypeX on DailyWarmUpAnswerResultType {
  String get trackingName {
    return switch (this) {
      DailyWarmUpAnswerResultType.correct => 'correct',
      DailyWarmUpAnswerResultType.incorrect => 'incorrect',
      DailyWarmUpAnswerResultType.neutral => 'neutral',
      DailyWarmUpAnswerResultType.unsupported => 'unsupported',
    };
  }
}

@freezed
abstract class DailyWarmUpAnswerResultEntity with _$DailyWarmUpAnswerResultEntity {
  const factory DailyWarmUpAnswerResultEntity({
    @Default(0) int questionId,
    @Default(0) int questionIndex,
    @Default(QuestionTypeEnum.singleChoice) QuestionTypeEnum questionType,
    @Default(FormDragDropType.textGapFilling) FormDragDropType questionForm,
    @Default(DailyWarmUpAnswerResultType.unsupported) DailyWarmUpAnswerResultType type,
    @Default(false) bool isCorrect,
    @Default([]) List<int> selectedIndices,
    @Default([]) List<int> correctIndices,
    @Default([]) List<int> selectedOptionIds,
    @Default([]) List<int> correctOptionIds,
  }) = _DailyWarmUpAnswerResultEntity;
}
