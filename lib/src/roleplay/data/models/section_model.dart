part of '../../roleplay.dart';

@freezed
abstract class SectionModel with _$SectionModel {
  const factory SectionModel({
    @Default(0) int id,
    @Default('') String title,
    @Default('') String transition,
    @Default('') String transitionColor,
    @Default('') String image,
    @Default([]) List<SectionContentModel> contents,
  }) = _SectionModel;

  factory SectionModel.fromJson(Map<String, dynamic> json) => _$SectionModelFromJson(json);
}

extension SectionModelExtension on SectionModel {
  SectionEntity toEntity() => SectionEntity(
    id: id,
    title: title,
    transition: transition,
    transitionColor: transitionColor,
    image: image,
    contents: contents.map((model) => model.toEntity()).toList(),
  );
}
