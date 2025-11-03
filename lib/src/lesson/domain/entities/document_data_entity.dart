part of '../../lesson.dart';

@freezed
abstract class DocumentDataEntity with _$DocumentDataEntity {
  const factory DocumentDataEntity({
    @Default('') String title,
    @Default('') String content,
    @Default('') String caption,
    @Default('') String url,
    @Default('') String thumbnail,
  }) = _DocumentDataEntity;

  factory DocumentDataEntity.fromJson(Map<String, dynamic> json) => _$DocumentDataEntityFromJson(json);
}

