part of '../../roleplay.dart';

@freezed
abstract class RoleplayEntity with _$RoleplayEntity {
  const factory RoleplayEntity({
    @Default(0) int id,
    @Default('') String image,
    @Default([]) List<RoleplayContentEntity> contents,
    @Default([]) List<RoleplayMissionEntity> missions,
  }) = _RoleplayEntity;

  factory RoleplayEntity.fromJson(Map<String, dynamic> json) => _$RoleplayEntityFromJson(json);
}

extension RoleplayEntityExtension on RoleplayEntity {
  List<QuestionEntity> get questions {
    if (contents.isEmpty) return [];
    List<QuestionEntity> questions = [];
    for (var content in contents) {
      if (content.type == RoleplayContentType.exercise) {
        questions.add(content.exercise);
      }
    }
    return questions;
  }
}
