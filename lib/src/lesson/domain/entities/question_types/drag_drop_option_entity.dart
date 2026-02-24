part of '../../../lesson.dart';

@freezed
abstract class QuestionDragDropOptionEntity with _$QuestionDragDropOptionEntity {
  const factory QuestionDragDropOptionEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage text,
  }) = _QuestionDragDropOptionEntity;

  factory QuestionDragDropOptionEntity.fromJson(Map<String, dynamic> json) => _$QuestionDragDropOptionEntityFromJson(json);
}
