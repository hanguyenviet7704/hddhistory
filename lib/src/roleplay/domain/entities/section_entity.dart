part of '../../roleplay.dart';

@freezed
abstract class SectionEntity with _$SectionEntity {
  const factory SectionEntity({
    @Default('') String id,
    @Default('') String title,
    @Default('') String transition,
    @Default('') String transitionColor,
    @Default('') String image,
    @Default([]) List<SectionContentEntity> contents,
  }) = _SectionEntity;

  factory SectionEntity.fromJson(Map<String, dynamic> json) => _$SectionEntityFromJson(json);
}
