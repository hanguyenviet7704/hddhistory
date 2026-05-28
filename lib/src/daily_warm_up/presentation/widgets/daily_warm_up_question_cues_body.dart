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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          context.l10n.exercise.exerciseStressMarkInstruction,
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          maxLines: 10,
          style: AppStyle.text12.copyWith(
            color: const Color(0xFF7F8EA4).withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        12.verticalSpace,
        Container(
          key: const ValueKey('daily-warm-up-cues-sentence-container'),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 2,
                strokeAlign: BorderSide.strokeAlignOutside,
                color: Color(0xFFE3E8EF),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Wrap(
            spacing: 2.w,
            runSpacing: 6.h,
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
        ),
        24.verticalSpace,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: CuesPlacementAvailableMarks(
            allOptions: options,
            availableOptions: availableOptions,
            onAcceptReturn: (data) {
              final fromWordIndex = data.fromWordIndex;
              if (fromWordIndex != null) onRemovePlacedOption(fromWordIndex);
            },
          ),
        ),
        20.verticalSpace,
      ],
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
