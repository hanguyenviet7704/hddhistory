part of '../../../lesson.dart';

class MultipleChoiceLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const MultipleChoiceLessonBody({
    super.key,
    required this.onAnswerChecked,
  });

  void _showResultBottomSheet(BuildContext context, ResultType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      routeSettings: const RouteSettings(name: RouteNamed.exerciseResultPopup),
      builder: (modalContext) => BlocProvider.value(
        value: context.read<ChoiceCubit>(),
        child: BlocBuilder<ChoiceCubit, ChoiceState>(
          bloc: context.read<ChoiceCubit>(),
          builder: (context, state) {
            return PopScope(
              canPop: false,
              child: Stack(
                children: [
                  // Animated backdrop overlay
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    opacity: state.showExplanation ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !state.showExplanation,
                      child: GestureDetector(
                        onTap: () => context.read<ChoiceCubit>().toggleExplanation(),
                        child: Container(
                          color: const Color(0xFF364152).withAlpha((0.6 * 255).round()),
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  // Result bottom sheet
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ResultBottomSheet(
                      type: type,
                      showExplanation: state.showExplanation,
                      explanationText: state.question.explanation,
                      onContinue: () {
                        modalContext.back();
                        AppDI.injector.get<ExerciseCubit>().nextQuestion();
                      },
                      onExplain: () {
                        context.read<ChoiceCubit>().toggleExplanation();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChoiceCubit, ChoiceState>(
      listenWhen: (previous, current) {
        // Only trigger when hasChecked changes from false to true
        return !previous.hasChecked && current.hasChecked;
      },
      listener: (context, state) {
        onAnswerChecked(state.isCorrect);
        _showResultBottomSheet(
          context,
          state.isCorrect ? ResultType.correct : ResultType.incorrect,
        );
      },
      child: BlocBuilder<ChoiceCubit, ChoiceState>(
        builder: (context, state) {
          final currentQuestion = state.question;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.document.isNotEmpty) ...[
                DocumentWidget(documents: currentQuestion.document),
                12.verticalSpace,
              ],
              AppText(
                context.text.exerciseMultiChoicesInstruction,
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                maxLines: 10,
                style: AppStyle.text12.copyWith(
                  color: const Color(0xFF7F8EA4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentQuestion.options.length,
                separatorBuilder: (context, index) => 12.verticalSpace,
                itemBuilder: (context, index) {
                  return MultipleChoiceAnswerCard(
                    option: currentQuestion.options[index],
                    state: state.getAnswerState(index),
                    onTap: () => context.read<ChoiceCubit>().selectAnswer(index),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build the bottom button for multiple choice questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<ChoiceCubit, ChoiceState>(
      builder: (context, state) {
        // if (state.hasChecked) {
        //   return const SizedBox.shrink();
        // }

        final canCheck = state.selectedAnswersIndices.isNotEmpty;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<ChoiceCubit>().checkAnswer() : null,
          text: 'Check',
          isEnabled: canCheck,
        );
      },
    );
  }
}
