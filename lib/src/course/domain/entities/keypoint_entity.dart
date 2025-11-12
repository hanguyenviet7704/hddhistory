part of '../../course.dart';

@freezed
abstract class KeypointEntity with _$KeypointEntity {
  const factory KeypointEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default(0) int index,
    @Default(StrengthLevel.optionalPractice) StrengthLevel strengthLevelData,
    @Default([]) List<LearningItemEntity> learningItems,
    @Default(ProcessEnum.notStarted) ProcessEnum progess,

    //* Custom Fields
    @Default(0) int point,
  }) = _KeypointEntity;

  factory KeypointEntity.fromJson(Map<String, dynamic> json) => _$KeypointEntityFromJson(json);
}

extension KeypointEntityExtension on KeypointEntity {
  bool get isCompleted => progess == ProcessEnum.done;

  StrengthLevel get strengthLevel {
    if (point == 0) return strengthLevelData;
    if (point >= 0 && point <= 40) return StrengthLevel.weakPoint;
    if (point > 40 && point <= 75) return StrengthLevel.morePractice;
    if (point > 75 && point <= 100) return StrengthLevel.optionalPractice;
    return StrengthLevel.optionalPractice;
  }
}
