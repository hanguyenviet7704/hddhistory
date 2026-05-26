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
    required this.onRemovePlacedOption,
    required this.onToggleWordIndex,
  });

  final DailyWarmUpState state;
  final VoidCallback onClose;
  final VoidCallback onCheck;
  final ValueChanged<int> onSelectChoice;
  final ValueChanged<List<int>> onSetOrderedOptionIds;
  final void Function(int slotIndex, int optionId) onPlaceOption;
  final ValueChanged<int> onRemovePlacedOption;
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
                    24.verticalSpace,
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: AppText(
                        question.questionText,
                        maxLines: 12,
                        style: AppStyle.text20.copyWith(
                          color: const Color(0xFF0D121C),
                          fontWeight: FontWeight.w700,
                          height: 1.5,
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
        enableSafeArea: true,
      ),
    );
  }

  Widget _buildQuestionBody(BuildContext context, QuestionEntity question) {
    final payload = question.typedPayload;
    return switch (payload) {
      QuestionSingleChoicePayloadEntity() || QuestionMultipleChoicePayloadEntity() || QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => DailyWarmUpChoiceBody(
        state: state,
        question: question,
        onSelectChoice: onSelectChoice,
      ),
      QuestionDragAndDropPayloadEntity(:final answers) => DailyWarmUpDragDropBody(
        state: state,
        question: question,
        slotCount: answers.length,
        onPlaceOption: onPlaceOption,
        onRemovePlacedOption: onRemovePlacedOption,
      ),
      QuestionArrangeTheSequencePayloadEntity() => DailyWarmUpArrangeBody(
        state: state,
        question: question,
        onSetOrderedOptionIds: onSetOrderedOptionIds,
      ),
      QuestionCuesPlacementPayloadEntity(:final targetArea) => DailyWarmUpCuesBody(
        state: state,
        question: question,
        words: _targetWords(targetArea),
        onPlaceOption: onPlaceOption,
        onRemovePlacedOption: onRemovePlacedOption,
      ),
      QuestionStressPlacementPayloadEntity(:final targetArea) => DailyWarmUpStressBody(
        state: state,
        words: _targetWords(targetArea),
        onToggleWordIndex: onToggleWordIndex,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
