part of '../../progress.dart';

@freezed
abstract class CompletedLevelAdditionalContentRequestModel with _$CompletedLevelAdditionalContentRequestModel {
  const factory CompletedLevelAdditionalContentRequestModel({
    @Default(false) bool requested,
    String? requestText,
    required DateTime submittedAt,
  }) = _CompletedLevelAdditionalContentRequestModel;

  factory CompletedLevelAdditionalContentRequestModel.fromJson(
    Map<String, dynamic> json,
  ) => _$CompletedLevelAdditionalContentRequestModelFromJson(json);
}

@freezed
abstract class CompletedLevelModel with _$CompletedLevelModel {
  const factory CompletedLevelModel({
    @JsonKey(unknownEnumValue: CourseLevel.unknown) @Default(CourseLevel.unknown) CourseLevel level,
    required DateTime completedAt,
    CompletedLevelAdditionalContentRequestModel? additionalContentRequest,
  }) = _CompletedLevelModel;

  factory CompletedLevelModel.fromJson(Map<String, dynamic> json) => _$CompletedLevelModelFromJson(json);
}

extension CompletedLevelAdditionalContentRequestModelExtension on CompletedLevelAdditionalContentRequestModel {
  CompletedLevelAdditionalContentRequestEntity toEntity() => CompletedLevelAdditionalContentRequestEntity(
    requested: requested,
    requestText: requestText,
    submittedAt: submittedAt,
  );
}

extension CompletedLevelModelExtension on CompletedLevelModel {
  CompletedLevelEntity toEntity() => CompletedLevelEntity(
    level: level,
    completedAt: completedAt,
    additionalContentRequest: additionalContentRequest?.toEntity(),
  );
}
