part of '../../lesson.dart';

UpdateUserProgressExerciseOptionValue? _progressValueFromBase(BaseMultiLanguage value) {
  final en = value.en.trim();
  final vi = value.vi.trim();
  if (en.isEmpty && vi.isEmpty) return null;
  return UpdateUserProgressExerciseOptionValue(
    en: en.isNotEmpty ? en : null,
    vi: vi.isNotEmpty ? vi : null,
  );
}

BaseMultiLanguage _progressPickValue(OptionEntity option) {
  final hasValue = option.value.en.trim().isNotEmpty || option.value.vi.trim().isNotEmpty || option.value.zh.trim().isNotEmpty;
  if (hasValue) return option.value;
  return option.text;
}

BaseMultiLanguage _progressPickText(OptionEntity option) {
  final hasText = option.text.en.trim().isNotEmpty || option.text.vi.trim().isNotEmpty || option.text.zh.trim().isNotEmpty;
  if (hasText) return option.text;
  return option.value;
}

UpdateUserProgressExerciseOption? _progressOptionFromOption(OptionEntity option) {
  final value = _progressValueFromBase(_progressPickValue(option));
  if (value == null) return null;
  return UpdateUserProgressExerciseOption(
    value: value,
    isCorrect: option.isCorrect,
  );
}

UpdateUserProgressExerciseDragDropOption? _progressDragDropFromOption(OptionEntity option) {
  final textValue = _progressValueFromBase(_progressPickText(option));
  final hasId = option.id > 0;
  if (!hasId && textValue == null) return null;
  return UpdateUserProgressExerciseDragDropOption(
    id: hasId ? option.id : null,
    text: textValue,
  );
}

List<UpdateUserProgressExerciseDragDropOption>? _progressDragDropList(Iterable<OptionEntity> options) {
  final mapped = options.map(_progressDragDropFromOption).whereType<UpdateUserProgressExerciseDragDropOption>().toList();
  if (mapped.isEmpty) return null;
  return mapped;
}

List<UpdateUserProgressExerciseOption>? _progressOptionList(Iterable<OptionEntity> options) {
  final mapped = options.map(_progressOptionFromOption).whereType<UpdateUserProgressExerciseOption>().toList();
  if (mapped.isEmpty) return null;
  return mapped;
}

UpdateUserProgressExerciseOption? _progressSingleOption(OptionEntity option) {
  return _progressOptionFromOption(option);
}

UpdateUserProgressExerciseOption? progressSingleOptionNoCorrect(OptionEntity option) {
  final value = _progressValueFromBase(_progressPickValue(option));
  if (value == null) return null;
  return UpdateUserProgressExerciseOption(
    value: value,
  );
}

UpdateUserProgressExerciseRecordAnswer? _progressRecordAnswer(AnswerEntity answer) {
  final record = answer.record.trim();
  final review = answer.review.trim();
  if (record.isEmpty && review.isEmpty) return null;
  return UpdateUserProgressExerciseRecordAnswer(
    record: record.isNotEmpty ? record : null,
    review: review.isNotEmpty ? review : null,
  );
}
