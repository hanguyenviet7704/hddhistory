part of '../../course.dart';

@freezed
abstract class KeypointEntity with _$KeypointEntity {
  const factory KeypointEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default(BaseMultiLanguage()) BaseMultiLanguage estimateCompleTime,
    @Default('') String image,
    @Default(0) int index,
    @Default(StrengthLevel.weakPoint) StrengthLevel strengthLevelData,
    @Default([]) List<LearningItemEntity> learningItems,
    @Default(ProcessEnum.notStarted) ProcessEnum progess,

    //* Custom Fields
    @Default(0) int point,
    @Default(false) bool isUseRoleplayModule,
    @Default(false) bool isUseProgressData,
  }) = _KeypointEntity;

  factory KeypointEntity.fromJson(Map<String, dynamic> json) => _$KeypointEntityFromJson(json);
}

extension KeypointEntityExtension on KeypointEntity {
  bool get isCompleted => progess == ProcessEnum.done;

  StrengthLevel get strengthLevel {
    if (!isUseRoleplayModule && !isUseProgressData) return strengthLevelData;
    if (point >= 0 && point <= 50) return StrengthLevel.weakPoint;
    if (point > 50 && point <= 84) return StrengthLevel.morePractice;
    if (point > 85 && point <= 100) return StrengthLevel.optionalPractice;
    return StrengthLevel.optionalPractice;
  }

  String get trackingName => title.en;

  String get trackingNameOrText => title.en.isNotEmpty ? title.en : title.text;
}
