part of '../../roleplay.dart';

@freezed
abstract class SectionContentEntity with _$SectionContentEntity {
  const factory SectionContentEntity({
    @Default(0) int id,
    @Default(RoleplaySectionType.conversation) RoleplaySectionType type,
    @Default(ConversationEntity()) ConversationEntity conversation,
    @Default(LeadingTextEntity()) LeadingTextEntity leadingText,
    @Default(HintEntity()) HintEntity hint,
    @Default(QuestionEntity()) QuestionEntity exercise,
  }) = _SectionContentEntity;

  factory SectionContentEntity.fromJson(Map<String, dynamic> json) => _$SectionContentEntityFromJson(json);
}
