part of '../../learning_import.dart';

@freezed
abstract class LearningImportJobModel with _$LearningImportJobModel {
  const factory LearningImportJobModel({
    @Default('') String id,
    // `unknownEnumValue` on every wire enum: a status or stage the server adds
    // later must degrade to `unknown`, not throw and fail the whole poll.
    @JsonKey(unknownEnumValue: ImportJobStatusEntity.unknown)
    @Default(ImportJobStatusEntity.unknown)
    ImportJobStatusEntity status,
    @JsonKey(unknownEnumValue: ImportJobStageEntity.unknown)
    ImportJobStageEntity? stage,
    @Default(0) int percent,
    @JsonKey(unknownEnumValue: ImportSourceTypeEntity.unknown)
    @Default(ImportSourceTypeEntity.unknown)
    ImportSourceTypeEntity sourceType,
    @Default('') String sourceLabel,
    @Default('') String outputLocale,
    String? userLessonId,
    String? errorCode,
  }) = _LearningImportJobModel;

  factory LearningImportJobModel.fromJson(Map<String, dynamic> json) =>
      _$LearningImportJobModelFromJson(json);
}

extension LearningImportJobModelX on LearningImportJobModel {
  LearningImportJobEntity toEntity() => LearningImportJobEntity(
    id: id,
    status: status,
    stage: stage,
    percent: percent,
    sourceType: sourceType,
    sourceLabel: sourceLabel,
    outputLocale: outputLocale,
    userLessonId: userLessonId,
    errorCode: errorCode,
  );
}
