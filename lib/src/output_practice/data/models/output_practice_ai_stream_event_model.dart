part of '../../output_practice.dart';

@Freezed(unionKey: 'type')
abstract class OutputPracticeAiStreamEvent with _$OutputPracticeAiStreamEvent {
  @FreezedUnionValue('stream')
  const factory OutputPracticeAiStreamEvent.stream({
    @Default('') String content,
  }) = _OutputPracticeAiStreamEventStream;

  @FreezedUnionValue('end')
  const factory OutputPracticeAiStreamEvent.end() = _OutputPracticeAiStreamEventEnd;

  @FreezedUnionValue('metadata_update')
  const factory OutputPracticeAiStreamEvent.metadataUpdate({
    String? keypointName,
    String? practiceOption,
    String? sectionId,
    bool? isSummaryTurn,
  }) = _OutputPracticeAiStreamEventMetadataUpdate;

  @FreezedUnionValue('error')
  const factory OutputPracticeAiStreamEvent.error({
    @Default('') String content,
  }) = _OutputPracticeAiStreamEventError;

  @FreezedUnionValue('unknown')
  const factory OutputPracticeAiStreamEvent.unknown({
    @Default('') String type,
  }) = _OutputPracticeAiStreamEventUnknown;

  factory OutputPracticeAiStreamEvent.fromJson(Map<String, dynamic> json) =>
      _$OutputPracticeAiStreamEventFromJson(json);
}
