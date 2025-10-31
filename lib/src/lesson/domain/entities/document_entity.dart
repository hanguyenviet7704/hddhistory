part of '../../lesson.dart';

@freezed
abstract class DocumentEntity with _$DocumentEntity {
  const factory DocumentEntity({
    @Default(0) int id,
    @Default('') String speechBubble,
    @Default(TagEntity()) TagEntity tag,
    @Default([]) List<ContentDocumentEntity> document,
  }) = _DocumentEntity;

  factory DocumentEntity.fromJson(Map<String, dynamic> json) => _$DocumentEntityFromJson(json);
}
