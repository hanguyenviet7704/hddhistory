part of '../../lesson.dart';

@freezed
abstract class TagEntity with _$TagEntity {
  const factory TagEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage(en: '')) BaseMultiLanguage title,
    @Default('') String color,
    @Default('') String url,
    @Default(AppUser()) AppUser createdBy,
    @Default(AppUser()) AppUser updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TagEntity;

  factory TagEntity.fromJson(Map<String, dynamic> json) => _$TagEntityFromJson(json);
}
