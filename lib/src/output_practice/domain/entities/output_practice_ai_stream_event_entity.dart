part of '../../output_practice.dart';

@Freezed(unionKey: 'type')
abstract class OutputPracticeAiStreamEvent with _$OutputPracticeAiStreamEvent {
  @FreezedUnionValue('stream')
  const factory OutputPracticeAiStreamEvent.stream({
    @JsonKey(name: 'conversationId', fromJson: _outputPracticeStringFromJson) String? conversationId,
    @Default('') String content,
  }) = _OutputPracticeAiStreamEventStream;

  @FreezedUnionValue('end')
  const factory OutputPracticeAiStreamEvent.end({
    @JsonKey(name: 'conversationId', fromJson: _outputPracticeStringFromJson) String? conversationId,
  }) = _OutputPracticeAiStreamEventEnd;

  @FreezedUnionValue('metadata_update')
  const factory OutputPracticeAiStreamEvent.metadataUpdate({
    @JsonKey(name: 'conversationId', fromJson: _outputPracticeStringFromJson) String? conversationId,
    @JsonKey(name: 'keypoint_name', fromJson: _outputPracticeKeypointNameFromJson) String? keypointName,
    @JsonKey(name: 'practice_option', fromJson: _outputPracticeStringFromJson) String? practiceOption,
    @JsonKey(name: 'section_id', fromJson: _outputPracticeStringFromJson) String? sectionId,
    @JsonKey(name: 'is_summary_turn', fromJson: _outputPracticeBoolFromJson) bool? isSummaryTurn,
  }) = _OutputPracticeAiStreamEventMetadataUpdate;

  @FreezedUnionValue('error')
  const factory OutputPracticeAiStreamEvent.error({
    @JsonKey(name: 'conversationId', fromJson: _outputPracticeStringFromJson) String? conversationId,
    @Default('') String content,
  }) = _OutputPracticeAiStreamEventError;

  @FreezedUnionValue('unknown')
  const factory OutputPracticeAiStreamEvent.unknown({
    @JsonKey(name: 'conversationId', fromJson: _outputPracticeStringFromJson) String? conversationId,
    @Default('') String type,
  }) = _OutputPracticeAiStreamEventUnknown;

  factory OutputPracticeAiStreamEvent.fromJson(Map<String, dynamic> json) => _$OutputPracticeAiStreamEventFromJson(json);
}

String? _outputPracticeKeypointNameFromJson(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    final normalizedItems = value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
    if (normalizedItems.isEmpty) return null;
    return normalizedItems.join('\n');
  }
  return _outputPracticeStringFromJson(value);
}

String? _outputPracticeStringFromJson(dynamic value) {
  if (value == null) return null;
  final normalizedValue = value.toString().trim();
  return normalizedValue.isEmpty ? null : normalizedValue;
}

bool? _outputPracticeBoolFromJson(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalizedValue = value.trim().toLowerCase();
    if (normalizedValue == 'true' || normalizedValue == '1') return true;
    if (normalizedValue == 'false' || normalizedValue == '0') return false;
  }
  return null;
}
