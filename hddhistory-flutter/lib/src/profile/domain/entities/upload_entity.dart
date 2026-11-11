part of '../../profile.dart';

@freezed
abstract class UploadEntity with _$UploadEntity {
  const factory UploadEntity({
    @Default('') String key,
    @Default('') String url,
  }) = _UploadEntity;

  factory UploadEntity.fromJson(Map<String, dynamic> json) => _$UploadEntityFromJson(json);
}

