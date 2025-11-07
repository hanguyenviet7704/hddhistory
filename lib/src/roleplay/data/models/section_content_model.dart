part of '../../roleplay.dart';

@freezed
abstract class SectionContentModel with _$SectionContentModel {
  const factory SectionContentModel({
    @Default('') String id,
    @Default(RoleplaySectionType.conversation) RoleplaySectionType type,
    @Default(ConversationModel()) ConversationModel conversation,
    @Default(LeadingTextModel()) LeadingTextModel leadingText,
    @Default(HintModel()) HintModel hint,
    @Default(QuestionModel()) QuestionModel exercise,
  }) = _SectionContentModel;

  factory SectionContentModel.fromJson(Map<String, dynamic> json) => _$SectionContentModelFromJson(json);
}

extension SectionContentModelExtension on SectionContentModel {
  SectionContentEntity toEntity() => SectionContentEntity(
    id: id,
    type: type,
    conversation: conversation.toEntity(),
    leadingText: leadingText.toEntity(),
    hint: hint.toEntity(),
    exercise: exercise.toEntity(),
  );
}

enum RoleplaySectionType {
  @JsonValue('conversation')
  conversation,
  @JsonValue('leading_text')
  leadingText,
  @JsonValue('hint')
  hint,
  @JsonValue('exercise')
  exercise,
}
