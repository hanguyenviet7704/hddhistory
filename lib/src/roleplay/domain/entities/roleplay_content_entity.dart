part of '../../roleplay.dart';

@freezed
abstract class RoleplayContentEntity with _$RoleplayContentEntity {
  const factory RoleplayContentEntity({
    @Default(0) int id,
    @Default(RoleplayContentType.conversation) RoleplayContentType type,
    @Default(ConversationEntity()) ConversationEntity conversation,
    @Default(LeadingTextEntity()) LeadingTextEntity leadingText,
    @Default(TransitionEntity()) TransitionEntity transition,
    @Default(QuestionEntity()) QuestionEntity exercise,
  }) = _RoleplayContentEntity;

  factory RoleplayContentEntity.fromJson(Map<String, dynamic> json) => _$RoleplayContentEntityFromJson(json);
}

extension RoleplayContentEntityExtension on RoleplayContentEntity {
  bool get finishedExercise {
    if (type != RoleplayContentType.exercise) return false;
    return exercise.hasResult || exercise.isCompleted;
  }
}