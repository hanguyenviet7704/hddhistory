part of '../../lesson.dart';

@freezed
abstract class NoCorrectDocumentGroupModel with _$NoCorrectDocumentGroupModel {
  const factory NoCorrectDocumentGroupModel({
    @Default('') String id,
    @Default([]) List<ContentDocumentModel> documents,
  }) = _NoCorrectDocumentGroupModel;

  factory NoCorrectDocumentGroupModel.fromJson(Map<String, dynamic> json) => _$NoCorrectDocumentGroupModelFromJson(json);
}

extension NoCorrectDocumentGroupModelExtension on NoCorrectDocumentGroupModel {
  QuestionNoCorrectDocumentGroupEntity toEntity() => QuestionNoCorrectDocumentGroupEntity(
    id: id,
    documents: documents.map((model) => model.toEntity()).toList(),
  );
}
