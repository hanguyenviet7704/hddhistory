part of '../../course.dart';

@freezed
abstract class KeypointModel with _$KeypointModel {
  const factory KeypointModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default(BaseMultiLanguage()) BaseMultiLanguage estimateCompleTime,
    @Default('') String image,
    @Default(0) int index,
    @Default(StrengthLevel.weakPoint) StrengthLevel strengthLevel,
    @Default([]) List<LearningItemModel> learningItems,
    @Default(-1) int averageScore,
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

  String title(BuildContext context) => switch (this) {
    weakPoint => context.text.keypoint.keypointWeakpointTitle,
    morePractice => context.text.keypoint.keypointImprovementTitle,
    optionalPractice => context.text.keypoint.keypointSkipOptionPracticeType,
  };
}

extension KeypointModelExtension on KeypointModel {
  KeypointEntity toEntity() => KeypointEntity(
    id: id,
    title: title,
    estimateCompleTime: estimateCompleTime,
    description: description,
    image: image,
    index: index,
    strengthLevelData: strengthLevel,
    averageScore: averageScore,
    progess: progess,
    learningItems: learningItems.map((model) => model.toEntity()).toList(),
  );
}