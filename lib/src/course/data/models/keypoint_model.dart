part of '../../course.dart';

@freezed
abstract class KeypointModel with _$KeypointModel {
  const factory KeypointModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default(0) int index,
    @Default(StrengthLevel.optionalPractice) StrengthLevel strengthLevel,
    @Default([]) List<LearningItemModel> learningItems,
    @Default(ProcessEnum.notStarted) ProcessEnum progess,
  }) = _KeypointModel;

  factory KeypointModel.fromJson(Map<String, dynamic> json) => _$KeypointModelFromJson(json);
}

enum StrengthLevel {
  @JsonValue('weak_point')
  weakPoint,
  @JsonValue('more_practice')
  morePractice,
  @JsonValue('optional_practice')
  optionalPractice;

  String get point => switch (this) {
    weakPoint => '0-50',
    morePractice => '51-84',
    optionalPractice => '85-100',
  };
}

extension KeypointModelExtension on KeypointModel {
  KeypointEntity toEntity() => KeypointEntity(
    id: id,
    title: title,
    description: description,
    image: image,
    index: index,
    strengthLevelData: strengthLevel,
    progess: progess,
    learningItems: learningItems.map((model) => model.toEntity()).toList(),
  );
}
