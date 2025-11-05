part of '../../course.dart';

@freezed
abstract class KeypointEntity with _$KeypointEntity {
  const factory KeypointEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default(0) int index,
    @Default(StrengthLevel.optionalPractice) StrengthLevel strengthLevel,
    @Default([]) List<LearningItemEntity> learningItems,
    @Default(ProcessEnum.notStarted) ProcessEnum progess,
  }) = _KeypointEntity;

  factory KeypointEntity.fromJson(Map<String, dynamic> json) => _$KeypointEntityFromJson(json);
}

extension KeypointEntityExtension on KeypointEntity {
  bool get isCompleted => progess == ProcessEnum.done;
}