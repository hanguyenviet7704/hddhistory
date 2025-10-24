part of '../../exercise.dart';

@freezed
abstract class DocumentData with _$DocumentData {
  const factory DocumentData({
    @Default('') String url,
  }) = _DocumentData;

  factory DocumentData.fromJson(Map<String, dynamic> json) => _$DocumentDataFromJson(json);
}

extension DocumentDataExtension on DocumentData {
  DocumentDataEntity toEntity() => DocumentDataEntity(
    url: url,
  );
}