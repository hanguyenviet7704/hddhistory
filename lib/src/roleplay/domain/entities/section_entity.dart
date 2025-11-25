part of '../../roleplay.dart';

@freezed
abstract class SectionEntity with _$SectionEntity {
  const factory SectionEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage transition,
    @Default('') String textColor,
    @Default('') String backgroundColor,
    @Default('') String image,
    @Default([]) List<SectionContentEntity> contents,
  }) = _SectionEntity;

  factory SectionEntity.fromJson(Map<String, dynamic> json) => _$SectionEntityFromJson(json);
}

extension SectionEntityExtension on SectionEntity {
  List<QuestionEntity> get questions {
    if (contents.isEmpty) return [];
    List<QuestionEntity> questions = [];
    for (var content in contents) {
      if (content.type == RoleplaySectionType.exercise) {
        questions.add(content.exercise);
      }
    }
    return questions;
  }
}