part of '../../lesson.dart';

@freezed
abstract class TagModel with _$TagModel {
  const factory TagModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default('') String color,
    @Default('') String url,
    @Default(UserModel()) UserModel createdBy,
    @Default(UserModel()) UserModel updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TagModel;

  factory TagModel.fromJson(Map<String, dynamic> json) => _$TagModelFromJson(json);
}

extension TagModelExtension on TagModel {
  TagEntity toEntity() => TagEntity(
    id: id,
    createdBy: createdBy.toEntity(),
    updatedBy: updatedBy.toEntity(),
    title: title,
    color: color,
    url: url,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
