part of '../../lesson.dart';

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
  bool get dataAvailable {
    final hasBaseData = data.content.text.isNotEmpty || data.url.text.isNotEmpty || data.thumbnail.isNotEmpty;
    final hasExplanationOptions = type == ContentDocumentType.explanation && data.options.isNotEmpty;

    return hasBaseData || hasExplanationOptions;
  }
}
