part of '../../lesson.dart';

@freezed
abstract class DocumentDataEntity with _$DocumentDataEntity {
  const factory DocumentDataEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    @Default(BaseMultiLanguage()) BaseMultiLanguage url,
    @Default('') String thumbnail,
    @Default([]) List<ExplanationOptionEntity> options,
  }) = _DocumentDataEntity;

  factory DocumentDataEntity.fromJson(Map<String, dynamic> json) => _$DocumentDataEntityFromJson(json);
}
