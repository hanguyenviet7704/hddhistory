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
    @JsonKey(unknownEnumValue: StrengthLevel.unknown) @Default(StrengthLevel.weakPoint) StrengthLevel strengthLevel,
    KeypointAudioModel? audio,
    @Default([]) List<LearningItemModel> learningItems,
    @Default(-1) int averageScore,
    @JsonKey(unknownEnumValue: ProcessEnum.unknown) @Default(ProcessEnum.notStarted) ProcessEnum progess,
  }) = _KeypointModel;

  factory KeypointModel.fromJson(Map<String, dynamic> json) => _$KeypointModelFromJson(json);
}

enum StrengthLevel {
  @JsonValue('weak_point')
  weakPoint,
  @JsonValue('more_practice')
  morePractice,
  @JsonValue('optional_practice')
  optionalPractice,
  @JsonValue('unknown')
  unknown
  ;

  String get point => switch (this) {
    weakPoint => '0-50',
    morePractice => '51-84',
    optionalPractice => '85-100',
    unknown => '0-0',
  };

  String title(BuildContext context) => switch (this) {
    weakPoint => context.l10n.keypoint.keypointWeakpointTitle,
    morePractice => context.l10n.keypoint.keypointImprovementTitle,
    optionalPractice => context.l10n.keypoint.keypointSkipOptionPracticeType,
    unknown => context.l10n.keypoint.keypointWeakpointTitle,
  };
}

extension KeypointModelExtension on KeypointModel {
  KeypointEntity toEntity() => KeypointEntity(
    id: id,
    title: title,
    estimateCompleTime: estimateCompleTime,
    description: description,
    audio: audio?.toEntity(),
    image: image,
    index: index,
    strengthLevelData: strengthLevel,
    averageScore: averageScore,
    progess: progess,
    learningItems: learningItems.map((model) => model.toEntity()).toList(),
  );
}
