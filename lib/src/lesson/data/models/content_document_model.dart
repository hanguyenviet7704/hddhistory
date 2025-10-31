part of '../../lesson.dart';

@freezed
abstract class ContentDocumentModel with _$ContentDocumentModel {
  const factory ContentDocumentModel({
    @Default(0) @JsonKey(name: '_id') int id,
    @Default(ContentDocumentType.text) ContentDocumentType type,
    @Default(DocumentDataModel()) DocumentDataModel data,
  }) = _ContentDocumentModel;

  factory ContentDocumentModel.fromJson(Map<String, dynamic> json) => _$ContentDocumentModelFromJson(json);
}

enum ContentDocumentType {
  @JsonValue('text')
  text,
  @JsonValue('video')
  video,
  @JsonValue('image')
  image,
  @JsonValue('audio')
  audio,
}

extension ContentDocumentModelExtension on ContentDocumentModel {
  ContentDocumentEntity toEntity() => ContentDocumentEntity(
    id: id,
    type: type,
    data: data.toEntity(),
  );
}
