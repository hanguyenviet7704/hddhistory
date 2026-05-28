part of '../../daily_warm_up.dart';

List<OptionEntity> _dailyWarmUpOptions(QuestionEntity question) {
  return questionRuntimeOptions(question).where((option) => option.id != 0 && option.labelText.trim().isNotEmpty).toList(growable: false);
}

OptionEntity? _dailyWarmUpOptionById(List<OptionEntity> options, int optionId) {
  for (final option in options) {
    if (option.id == optionId) return option;
  }
  return null;
}

OptionEntity? _dailyWarmUpFirstAvailableByLabel(List<OptionEntity> options, Map<int, int> placedOptionIds, String label) {
  for (final option in options) {
    if (placedOptionIds.containsValue(option.id)) continue;
    if (option.labelText == label) return option;
  }
  return null;
}
