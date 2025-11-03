part of '../../lesson.dart';

@freezed
abstract class TagModel with _$TagModel {
  const factory TagModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default(AppUser()) AppUser createdBy,
    @Default(AppUser()) AppUser updatedBy,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default('') String color,
    @Default('') String icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TagModel;

  factory TagModel.fromJson(Map<String, dynamic> json) => _$TagModelFromJson(json);
}

extension TagModelExtension on TagModel {
  TagEntity toEntity() => TagEntity(
    id: id,
    createdBy: createdBy,
    updatedBy: updatedBy,
    title: title,
    color: color,
    icon: icon,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
