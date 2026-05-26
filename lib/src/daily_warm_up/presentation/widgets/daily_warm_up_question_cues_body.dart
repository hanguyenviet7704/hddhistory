part of '../../daily_warm_up.dart';

class DailyWarmUpCuesBody extends StatelessWidget {
  const DailyWarmUpCuesBody({
    super.key,
    required this.state,
    required this.question,
    required this.words,
    required this.onPlaceOption,
    required this.onRemovePlacedOption,
  });

  final DailyWarmUpState state;
  final QuestionEntity question;
  final List<String> words;
  final void Function(int slotIndex, int optionId) onPlaceOption;
  final ValueChanged<int> onRemovePlacedOption;

  @override
  Widget build(BuildContext context) {
    final options = _dailyWarmUpOptions(question);
    final availableOptions = options.where((option) => !state.placedOptionIds.containsValue(option.id)).toList(growable: false);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Wrap(
            spacing: 6.w,
            runSpacing: 10.h,
            alignment: WrapAlignment.center,
            children: List.generate(words.length, (index) {
              final placedOption = _dailyWarmUpOptionById(options, state.placedOptionIds[index] ?? 0);
              return CuesPlacementWordWithDropZone(
                word: words[index],
                wordIndex: index,
                placedMark: placedOption,
                markState: _markState(index),
                hasChecked: state.latestResult != null,
                onAcceptMark: (wordIndex, data) => onPlaceOption(wordIndex, data.optionId),
                onRemoveMark: onRemovePlacedOption,
              );
            }),
          ),
          28.verticalSpace,
          CuesPlacementAvailableMarks(
            allOptions: options,
            availableOptions: availableOptions,
            onAcceptReturn: (data) {
              final fromWordIndex = data.fromWordIndex;
              if (fromWordIndex != null) onRemovePlacedOption(fromWordIndex);
            },
          ),
        ],
      ),
    );
  }

  AnswerState? _markState(int index) {
    final isPlaced = state.placedOptionIds.containsKey(index);
    final result = state.latestResult;
    if (result == null) return isPlaced ? AnswerState.selected : null;
    final isCorrectPosition = result.correctIndices.contains(index);
    if (isPlaced && isCorrectPosition) return AnswerState.correct;
    if (isPlaced) return AnswerState.incorrect;
    return null;
  }
}
