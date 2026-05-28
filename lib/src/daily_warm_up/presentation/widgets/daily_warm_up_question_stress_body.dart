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
          key: const ValueKey('daily-warm-up-stress-sentence-container'),
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
              return MarkStressWordCard(
                option: OptionEntity(
                  id: index,
                  text: BaseMultiLanguage(en: words[index], vi: words[index], zh: words[index]),
                  value: BaseMultiLanguage(en: words[index], vi: words[index], zh: words[index]),
                ),
                state: _wordState(index),
                onTap: () => onToggleWordIndex(index),
              );
            }),
          ),
        ),
      ],
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
