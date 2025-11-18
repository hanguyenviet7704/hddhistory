part of '../../profile.dart';

@freezed
abstract class UploadModel with _$UploadModel {
  const factory UploadModel({
    @Default('') String key,
    @Default('') String url,
  }) = _UploadModel;

  factory UploadModel.fromJson(Map<String, dynamic> json) => _$UploadModelFromJson(json);
}

extension UploadModelExtension on UploadModel {
  UploadEntity toEntity() => UploadEntity(
    key: key,
    url: url,
  );
}
