part of '../../daily_warm_up.dart';

class DailyWarmUpDragDropBody extends StatelessWidget {
  const DailyWarmUpDragDropBody({
    super.key,
    required this.state,
    required this.question,
    required this.slotCount,
    required this.onPlaceOption,
    required this.onRemovePlacedOption,
  });

  final DailyWarmUpState state;
  final QuestionEntity question;
  final int slotCount;
  final void Function(int slotIndex, int optionId) onPlaceOption;
  final ValueChanged<int> onRemovePlacedOption;

  @override
  Widget build(BuildContext context) {
    final options = _dailyWarmUpOptions(question);
    final allWords = options.map((option) => option.labelText).toList(growable: false);
    final availableWords = options.where((option) => !state.placedOptionIds.containsValue(option.id)).map((option) => option.labelText).toList(growable: false);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Wrap(
            spacing: 8.w,
            runSpacing: 12.h,
            alignment: WrapAlignment.center,
            children: List.generate(slotCount, (index) {
              final option = _dailyWarmUpOptionById(options, state.placedOptionIds[index] ?? 0);
              return BlankSlot(
                index: index,
                placedWord: option?.labelText,
                slotState: _slotState(index),
                onWordPlaced: (word, fromIndex) {
                  final movedOptionId = fromIndex == null ? null : state.placedOptionIds[fromIndex];
                  final optionToPlace = movedOptionId == null
                      ? _dailyWarmUpFirstAvailableByLabel(options, state.placedOptionIds, word)
                      : _dailyWarmUpOptionById(options, movedOptionId);
                  if (optionToPlace != null) onPlaceOption(index, optionToPlace.id);
                },
                onWordRemoved: (_, fromIndex) => onRemovePlacedOption(fromIndex),
                onDragCancelled: (_, _) {},
              );
            }),
          ),
          32.verticalSpace,
          AnswerCardsArea(
            availableWords: availableWords,
            allWords: allWords,
            onWordReturnedFromSlot: (_, fromIndex) => onRemovePlacedOption(fromIndex),
          ),
        ],
      ),
    );
  }

  SlotState _slotState(int index) {
    final result = state.latestResult;
    if (result == null) return SlotState.normal;
    final placedOptionId = state.placedOptionIds[index];
    if (placedOptionId == null || index >= result.correctOptionIds.length) return SlotState.normal;
    return placedOptionId == result.correctOptionIds[index] ? SlotState.correct : SlotState.incorrect;
  }
}
