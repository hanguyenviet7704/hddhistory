part of '../../lesson.dart';

@freezed
abstract class DocumentModel with _$DocumentModel {
  const factory DocumentModel({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage speechBubble,
    @Default(TagModel()) TagModel tag,
    @Default([]) List<ContentDocumentModel> document,
  }) = _DocumentModel;

  factory DocumentModel.fromJson(Map<String, dynamic> json) => _$DocumentModelFromJson(json);
}

extension DocumentModelExtension on DocumentModel {
  DocumentEntity toEntity() => DocumentEntity(
    id: id,
    speechBubble: speechBubble,
    tag: tag.toEntity(),
    document: document.map((model) => model.toEntity()).toList(),
  );
}
