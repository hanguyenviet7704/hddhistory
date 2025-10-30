part of '../../../exercise.dart';

class ArrangeTheSequenceLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const ArrangeTheSequenceLessonBody({
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
        value: context.read<ArrangeTheSequenceCubit>(),
        child: BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
          bloc: context.read<ArrangeTheSequenceCubit>(),
          builder: (context, state) {
            // Get correct answer sequence by mapping answer IDs to options
            final correctAnswers = state.question.answer.map((answer) {
              return state.question.options.firstWhere(
                (option) => option.id == answer.id,
                orElse: () => const OptionEntity(),
              );
            }).toList();

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
                        onTap: () => context.read<ArrangeTheSequenceCubit>().toggleExplanation(),
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
                    child: ArrangeSequenceResultBottomSheet(
                      type: type,
                      showExplanation: state.showExplanation,
                      explanationText: state.question.explanation,
                      arrangedAnswers: correctAnswers,
                      onContinue: () {
                        modalContext.back();
                        AppDI.injector.get<ExerciseCubit>().nextQuestion();
                      },
                      onExplain: () {
                        context.read<ArrangeTheSequenceCubit>().toggleExplanation();
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
    return BlocListener<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
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
      child: BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
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
                context.text.exerciseSequenceInstruction,
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                maxLines: 10,
                style: AppStyle.text12
                    .copyWith(
                      color: const Color(0xFF7F8EA4),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    )
                    .copyWith(
                      color: const Color(0xFF7F8EA4).withValues(alpha: 0.6),
                    ),
              ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                proxyDecorator: (child, index, animation) {
                  return child;
                },
                onReorder: (oldIndex, newIndex) {
                  context.read<ArrangeTheSequenceCubit>().reorderItems(oldIndex, newIndex);
                },
                itemCount: state.currentItems.length,
                itemBuilder: (context, index) {
                  final item = state.currentItems[index];
                  return Padding(
                    key: Key('${item.id}'),
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: ArrangeSequenceAnswerCard(
                      text: item.text,
                      index: index,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build the bottom button for arrange the sequence questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>(
      builder: (context, state) {
        final canCheck = context.read<ArrangeTheSequenceCubit>().canCheck;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<ArrangeTheSequenceCubit>().checkAnswer() : null,
          text: 'Check',
          isEnabled: canCheck,
        );
      },
    );
  }
}
