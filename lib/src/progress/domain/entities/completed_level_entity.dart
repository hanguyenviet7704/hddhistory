part of '../../progress.dart';

@freezed
abstract class CompletedLevelAdditionalContentRequestEntity with _$CompletedLevelAdditionalContentRequestEntity {
  const factory CompletedLevelAdditionalContentRequestEntity({
    @Default(false) bool requested,
    String? requestText,
    required DateTime submittedAt,
  }) = _CompletedLevelAdditionalContentRequestEntity;

  factory CompletedLevelAdditionalContentRequestEntity.fromJson(
    Map<String, dynamic> json,
  ) => _$CompletedLevelAdditionalContentRequestEntityFromJson(json);
}

@freezed
abstract class CompletedLevelEntity with _$CompletedLevelEntity {
  const factory CompletedLevelEntity({
    @JsonKey(unknownEnumValue: CourseLevel.unknown) @Default(CourseLevel.unknown) CourseLevel level,
    required DateTime completedAt,
    CompletedLevelAdditionalContentRequestEntity? additionalContentRequest,
  }) = _CompletedLevelEntity;

  factory CompletedLevelEntity.fromJson(Map<String, dynamic> json) => _$CompletedLevelEntityFromJson(json);
}
