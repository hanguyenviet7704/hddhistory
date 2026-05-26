part of '../../daily_warm_up.dart';

class DailyWarmUpStressBody extends StatelessWidget {
  const DailyWarmUpStressBody({
    super.key,
    required this.state,
    required this.words,
    required this.onToggleWordIndex,
  });

  final DailyWarmUpState state;
  final List<String> words;
  final ValueChanged<int> onToggleWordIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Wrap(
        spacing: 6.w,
        runSpacing: 10.h,
        alignment: WrapAlignment.center,
        children: List.generate(words.length, (index) {
          return MarkStressWordCard(
            option: OptionEntity(
              id: index + 1,
              text: BaseMultiLanguage(en: words[index], vi: words[index], zh: words[index]),
            ),
            state: _wordState(index),
            onTap: () => onToggleWordIndex(index),
          );
        }),
      ),
    );
  }

  AnswerState _wordState(int index) {
    final isSelected = state.selectedWordIndices.contains(index);
    final result = state.latestResult;
    if (result == null) return isSelected ? AnswerState.selected : AnswerState.normal;

    final isCorrect = result.correctIndices.contains(index);
    if (isCorrect && isSelected) return AnswerState.correct;
    if (isSelected) return AnswerState.incorrect;
    if (isCorrect) return AnswerState.correctNotSelected;
    return AnswerState.disabled;
  }
}
