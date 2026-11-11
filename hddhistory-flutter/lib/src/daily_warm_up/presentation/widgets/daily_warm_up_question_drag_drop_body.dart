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
    final availableWords = options.where((option) => !state.placedOptionIds.containsValue(option.id)).map((option) => option.labelText).toList(growable: false);
    final targetArea = switch (question.typedPayload) {
      QuestionDragAndDropPayloadEntity(:final targetArea) => targetArea.text,
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DailyWarmUpSentenceBuilder(
          placedOptionIds: state.placedOptionIds,
          options: options,
          targetArea: targetArea,
          answerCount: slotCount,
          onOptionPlaced: onPlaceOption,
          onOptionRemoved: onRemovePlacedOption,
          getSlotState: _slotState,
        ),
        24.verticalSpace,
        AppText(
          context.l10n.exercise.exerciseGapFillingInstruction,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        12.verticalSpace,
        AnswerCardsArea(
          pool: options.map((option) => option.labelText).toList(growable: false),
          availableWords: availableWords,
          onWordReturnedFromSlot: (_, fromIndex) => onRemovePlacedOption(fromIndex),
        ),
      ],
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
