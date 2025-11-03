part of '../../roadmap.dart';

@freezed
abstract class KeypointModel with _$KeypointModel {
  const factory KeypointModel({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default(0) int index,
    @Default([]) List<LearningItemModel> learningItems,
  }) = _KeypointModel;

  factory KeypointModel.fromJson(Map<String, dynamic> json) => _$KeypointModelFromJson(json);
}

extension KeypointModelExtension on KeypointModel {
  KeypointEntity toEntity() => KeypointEntity(
    id: id,
    title: title,
    description: description,
    image: image,
    index: index,
    learningItems: learningItems.map((model) => model.toEntity()).toList(),
  );
}
