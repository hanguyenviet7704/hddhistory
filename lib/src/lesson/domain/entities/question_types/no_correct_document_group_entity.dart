part of '../../../lesson.dart';

@freezed
abstract class QuestionNoCorrectDocumentGroupEntity with _$QuestionNoCorrectDocumentGroupEntity {
  const factory QuestionNoCorrectDocumentGroupEntity({
    @Default('') String id,
    @Default([]) List<ContentDocumentEntity> documents,
  }) = _QuestionNoCorrectDocumentGroupEntity;

  factory QuestionNoCorrectDocumentGroupEntity.fromJson(Map<String, dynamic> json) => _$QuestionNoCorrectDocumentGroupEntityFromJson(json);
}
