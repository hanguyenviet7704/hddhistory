part of '../../exercise.dart';

@freezed
abstract class ContentDocumentEntity with _$ContentDocumentEntity {
  const factory ContentDocumentEntity({
    @Default(0) int id,
    @Default(ContentDocumentType.text) ContentDocumentType type,
    @Default(DocumentDataEntity()) DocumentDataEntity data,
  }) = _ContentDocumentEntity;

  factory ContentDocumentEntity.fromJson(Map<String, dynamic> json) => _$ContentDocumentEntityFromJson(json);
}

extension ContentDocumentEntityExtension on ContentDocumentEntity {
  bool get dataAvailable => data.title.isNotEmpty || data.content.isNotEmpty || data.caption.isNotEmpty || data.url.isNotEmpty || data.thumbnail.isNotEmpty;
}
