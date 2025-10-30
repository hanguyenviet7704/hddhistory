part of '../../../exercise.dart';

class MarkStressWordLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const MarkStressWordLessonBody({
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp))),
      routeSettings: const RouteSettings(name: RouteNamed.exerciseResultPopup),
      builder: (modalContext) => BlocProvider.value(
        value: context.read<MarkStressWordCubit>(),
        child: BlocBuilder<MarkStressWordCubit, MarkStressWordState>(
          bloc: context.read<MarkStressWordCubit>(),
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
                        onTap: () => context.read<MarkStressWordCubit>().toggleExplanation(),
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
                    child: MarkStressWordResultBottomSheet(
                      type: type,
                      showExplanation: state.showExplanation,
                      explanationText: state.question.explanation,
                      words: state.words,
                      selectedIndices: state.selectedWordIndices,
                      correctIndices: state.correctWordIndices,
                      onContinue: () {
                        modalContext.back();
                        AppDI.injector.get<ExerciseCubit>().nextQuestion();
                      },
                      onExplain: () {
                        context.read<MarkStressWordCubit>().toggleExplanation();
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
    return BlocListener<MarkStressWordCubit, MarkStressWordState>(
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
      child: BlocBuilder<MarkStressWordCubit, MarkStressWordState>(
        builder: (context, state) {
          final currentQuestion = state.question;
          final words = state.words;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.document.any((document) => document.dataAvailable)) ...[
                DocumentWidget(documents: currentQuestion.document),
                12.verticalSpace,
              ],
              AppText(
                context.text.exerciseStressMarkInstruction,
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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: const Color(0xFFE3E8EF) /* Border-border-secondary */,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Wrap(
                  spacing: 2.w,
                  runSpacing: 12.h,
                  alignment: WrapAlignment.spaceAround,
                  runAlignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,

                  children: List.generate(
                    words.length,
                    (index) {
                      // Create a temporary OptionEntity for each word
                      final wordOption = OptionEntity(
                        id: index,
                        text: words[index],
                        value: words[index],
                      );

                      return MarkStressWordCard(
                        option: wordOption,
                        state: state.getWordState(index),
                        onTap: () => context.read<MarkStressWordCubit>().selectWord(index),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build the bottom button for mark stress word questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<MarkStressWordCubit, MarkStressWordState>(
      builder: (context, state) {
        final canCheck = state.selectedWordIndices.isNotEmpty && !state.hasChecked;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<MarkStressWordCubit>().checkAnswer() : null,
          text: 'Check',
          isEnabled: canCheck,
        );
      },
    );
  }
}
