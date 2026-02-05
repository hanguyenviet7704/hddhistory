part of '../../roleplay.dart';

@freezed
abstract class RoleplayContentModel with _$RoleplayContentModel {
  const factory RoleplayContentModel({
    @Default(0) int id,
    @Default(RoleplayContentType.conversation) RoleplayContentType type,
    @Default(ConversationModel()) ConversationModel conversation,
    @Default(LeadingTextModel()) LeadingTextModel leadingText,
    @Default(TransitionModel()) TransitionModel transition,
    @Default(QuestionModel()) QuestionModel exercise,
  }) = _RoleplayContentModel;

  factory RoleplayContentModel.fromJson(Map<String, dynamic> json) => _$RoleplayContentModelFromJson(json);
}

extension RoleplayContentModelExtension on RoleplayContentModel {
  RoleplayContentEntity toEntity() => RoleplayContentEntity(
    id: id,
    type: type,
    conversation: conversation.toEntity(),
    leadingText: leadingText.toEntity(),
    transition: transition.toEntity(),
    exercise: exercise.toEntity(),
  );
}

enum RoleplayContentType {
  @JsonValue('conversation')
  conversation,
  @JsonValue('leading_text')
  leadingText,
  @JsonValue('transition')
  transition,
  @JsonValue('exercise')
  exercise,
}
