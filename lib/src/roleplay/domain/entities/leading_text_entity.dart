part of '../../roleplay.dart';

@freezed
abstract class LeadingTextEntity with _$LeadingTextEntity {
  const factory LeadingTextEntity({
    @Default('') String frameColor,
    @Default('') String textColor,
    @Default('') String content,
  }) = _LeadingTextEntity;

  factory LeadingTextEntity.fromJson(Map<String, dynamic> json) => _$LeadingTextEntityFromJson(json);
}
