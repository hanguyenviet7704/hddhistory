part of '../../roleplay.dart';

@freezed
abstract class SectionEntity with _$SectionEntity {
  const factory SectionEntity({
    @Default(0) int id,
    @Default('') String title,
    @Default('') String transition,
    @Default('') String textColor,
    @Default('') String backgroundColor,
    @Default('') String image,
    @Default([]) List<SectionContentEntity> contents,
  }) = _SectionEntity;

  factory SectionEntity.fromJson(Map<String, dynamic> json) => _$SectionEntityFromJson(json);
}
