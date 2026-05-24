part of '../../daily_warm_up.dart';

class DailyWarmUpQuestionStep extends StatelessWidget {
  const DailyWarmUpQuestionStep({
    super.key,
    required this.state,
    required this.onClose,
    required this.onCheck,
    required this.onSelectChoice,
    required this.onSetOrderedOptionIds,
    required this.onPlaceOption,
    required this.onToggleWordIndex,
  });

  final DailyWarmUpState state;
  final VoidCallback onClose;
  final VoidCallback onCheck;
  final ValueChanged<int> onSelectChoice;
  final ValueChanged<List<int>> onSetOrderedOptionIds;
  final void Function(int slotIndex, int optionId) onPlaceOption;
  final ValueChanged<int> onToggleWordIndex;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF0D121C)),
                  ),
                  Expanded(
                    child: Center(
                      child: DailyWarmUpProgressDots(
                        count: state.usableQuestions.length,
                        currentIndex: state.currentQuestionIndex,
                      ),
                    ),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                child: ListView(
                  key: ValueKey('${question.id}-${state.currentQuestionIndex}'),
                  padding: EdgeInsets.only(bottom: 20.h),
                  children: [
                    20.verticalSpace,
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: AppText(
                        question.questionText,
                        maxLines: 12,
                        style: AppStyle.text20.copyWith(
                          color: const Color(0xFF0D121C),
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    20.verticalSpace,
                    _buildQuestionBody(context, question),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DailyWarmUpBottomCta(
        label: context.l10n.dailyWarmUp.check,
        enabled: state.canCheckCurrentQuestion,
        onPressed: onCheck,
      ),
    );
  }

  Widget _buildQuestionBody(BuildContext context, QuestionEntity question) {
    final payload = question.typedPayload;
    return switch (payload) {
      QuestionSingleChoicePayloadEntity() || QuestionMultipleChoicePayloadEntity() || QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => _ChoiceBody(
        state: state,
        question: question,
        onSelectChoice: onSelectChoice,
      ),
      QuestionDragAndDropPayloadEntity(:final answers) => _OrderedOptionBody(
        state: state,
        question: question,
        slotCount: answers.length,
        onOptionTap: (slotIndex, optionId) => onPlaceOption(slotIndex, optionId),
      ),
      QuestionArrangeTheSequencePayloadEntity() => _ArrangeBody(
        state: state,
        question: question,
        onSetOrderedOptionIds: onSetOrderedOptionIds,
      ),
      QuestionCuesPlacementPayloadEntity(:final targetArea) => _PositionWordsBody(
        state: state,
        words: _targetWords(targetArea),
        onTap: (index) {
          final options = questionRuntimeOptions(question);
          if (options.isNotEmpty) onPlaceOption(index, options.first.id);
        },
      ),
      QuestionStressPlacementPayloadEntity(:final targetArea) => _PositionWordsBody(
        state: state,
        words: _targetWords(targetArea),
        onTap: onToggleWordIndex,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _ChoiceBody extends StatelessWidget {
  const _ChoiceBody({
    required this.state,
    required this.question,
    required this.onSelectChoice,
  });

  final DailyWarmUpState state;
  final QuestionEntity question;
  final ValueChanged<int> onSelectChoice;

  @override
  Widget build(BuildContext context) {
    final isMultiple = question.typedPayload is QuestionMultipleChoicePayloadEntity;
    final options = questionRuntimeOptions(question);
    return Column(
      children: [
        if (isMultiple)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: AppText(
              context.l10n.dailyWarmUp.selectAllThatApply,
              style: AppStyle.text12.copyWith(color: const Color(0xFF7F8EA4), fontWeight: FontWeight.w600),
            ),
          ),
        if (isMultiple) 12.verticalSpace,
        ...List.generate(options.length, (index) {
          final answerState = dailyWarmUpChoiceAnswerState(
            question: question,
            index: index,
            selectedAnswerIndex: state.selectedAnswerIndex,
            selectedAnswersIndices: state.selectedAnswersIndices,
            result: state.latestResult,
          );
          final card = isMultiple
              ? MultipleChoiceAnswerCard(option: options[index], state: answerState, onTap: () => onSelectChoice(index))
              : ChoiceAnswerCard(option: options[index], state: answerState, onTap: () => onSelectChoice(index));
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: card,
          );
        }),
      ],
    );
  }
}

class _OrderedOptionBody extends StatelessWidget {
  const _OrderedOptionBody({
    required this.state,
    required this.question,
    required this.slotCount,
    required this.onOptionTap,
  });

  final DailyWarmUpState state;
  final QuestionEntity question;
  final int slotCount;
  final void Function(int slotIndex, int optionId) onOptionTap;

  @override
  Widget build(BuildContext context) {
    final options = questionRuntimeOptions(question);
    final nextSlot = math.min(state.placedOptionIds.length, math.max(slotCount - 1, 0));
    return _OptionWrap(
      options: options,
      selectedIds: state.placedOptionIds.values.toSet(),
      onTap: (option) => onOptionTap(nextSlot, option.id),
    );
  }
}

class _ArrangeBody extends StatelessWidget {
  const _ArrangeBody({
    required this.state,
    required this.question,
    required this.onSetOrderedOptionIds,
  });

  final DailyWarmUpState state;
  final QuestionEntity question;
  final ValueChanged<List<int>> onSetOrderedOptionIds;

  @override
  Widget build(BuildContext context) {
    final options = questionRuntimeOptions(question);
    return _OptionWrap(
      options: options,
      selectedIds: state.orderedOptionIds.toSet(),
      onTap: (option) {
        final ids = List<int>.from(state.orderedOptionIds);
        ids.contains(option.id) ? ids.remove(option.id) : ids.add(option.id);
        onSetOrderedOptionIds(ids);
      },
    );
  }
}

class _PositionWordsBody extends StatelessWidget {
  const _PositionWordsBody({
    required this.state,
    required this.words,
    required this.onTap,
  });

  final DailyWarmUpState state;
  final List<String> words;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: List.generate(words.length, (index) {
          final selected = state.selectedWordIndices.contains(index) || state.placedOptionIds.containsKey(index);
          return ActionChip(
            label: Text(words[index]),
            backgroundColor: selected ? const Color(0xFFEFF0FE) : Colors.white,
            side: BorderSide(color: selected ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF), width: 1.5),
            onPressed: () => onTap(index),
          );
        }),
      ),
    );
  }
}

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({
    required this.options,
    required this.selectedIds,
    required this.onTap,
  });

  final List<OptionEntity> options;
  final Set<int> selectedIds;
  final ValueChanged<OptionEntity> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: options.map((option) {
          final selected = selectedIds.contains(option.id);
          return ActionChip(
            label: Text(option.labelText),
            backgroundColor: selected ? const Color(0xFFEFF0FE) : Colors.white,
            side: BorderSide(color: selected ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF), width: 1.5),
            onPressed: () => onTap(option),
          );
        }).toList(),
      ),
    );
  }
}
