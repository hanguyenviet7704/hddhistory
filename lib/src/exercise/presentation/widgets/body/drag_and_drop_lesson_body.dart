part of '../../../exercise.dart';

class DragAndDropLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const DragAndDropLessonBody({
    super.key,
    required this.onAnswerChecked,
  });

  void _showResultBottomSheet(BuildContext context, ResultType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      routeSettings: const RouteSettings(name: RouteNamed.exerciseResultPopup),
      builder: (modalContext) => BlocProvider.value(
        value: context.read<DragAndDropCubit>(),
        child: BlocBuilder<DragAndDropCubit, DragAndDropState>(
          bloc: context.read<DragAndDropCubit>(),
          builder: (context, state) {
            return Stack(
              children: [
                // Animated backdrop overlay
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  opacity: state.showExplanation ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !state.showExplanation,
                    child: GestureDetector(
                      onTap: () => context.read<DragAndDropCubit>().toggleExplanation(),
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
                  child: DragAndDropResultBottomSheet(
                    type: type,
                    showExplanation: state.showExplanation,
                    explanationText: state.question.explanation,
                    onContinue: () {
                      modalContext.back();
                    },
                    onExplain: () {
                      context.read<DragAndDropCubit>().toggleExplanation();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DragAndDropCubit, DragAndDropState>(
      listenWhen: (previous, current) {
        // Only trigger when hasChecked changes from false to true
        return !previous.hasChecked && current.hasChecked;
      },
      listener: (context, state) {
        onAnswerChecked(state.isCorrect);
        (context.findAncestorWidgetOfExactType<DragAndDropLessonBody>() as DragAndDropLessonBody)._showResultBottomSheet(
          context,
          state.isCorrect ? ResultType.correct : ResultType.incorrect,
        );
      },
      child: BlocBuilder<DragAndDropCubit, DragAndDropState>(
        builder: (context, state) {
          final currentQuestion = state.question;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.document.any((document) => document.dataAvailable)) ...[
                ChoiceDocumentWidget(documents: currentQuestion.document),
                12.verticalSpace,
              ],
              SentenceBuilder(
                placedWords: state.placedWords,
                targetArea: currentQuestion.targetArea,
                answerCount: state.dropZoneCount,
                onWordPlaced: (index, word, fromIndex) {
                  context.read<DragAndDropCubit>().placeWord(index, word, fromIndex);
                },
                onWordRemoved: (index) {
                  context.read<DragAndDropCubit>().removeWord(index);
                },
              ),
              12.verticalSpace,
              AppText(
                context.text.exerciseGapFillingInstruction,
                style: AppStyle.text12.copyWith(
                  color: const Color(0xFF7F8EA4).withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              12.verticalSpace,
              AnswerCardsArea(
                availableWords: state.availableWords,
                onWordReturnedFromSlot: (word, fromIndex) {
                  // Word is being dragged back to available area
                  // This is handled by removeWord in the cubit
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHintText(BuildContext context) {
    return Center(
      child: Column(
        children: [
          4.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                size: 14.sp,
                color: const Color(0xFF7F8EA4).withValues(alpha: 0.4),
              ),
              4.horizontalSpace,
              AppText(
                'Hold to drag • Drag back to remove',
                style: AppStyle.text10.copyWith(
                  color: const Color(0xFF7F8EA4).withValues(alpha: 0.4),
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build the bottom button for drag and drop questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<DragAndDropCubit, DragAndDropState>(
      builder: (context, state) {
        final canCheck = state.isAllFilled;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<DragAndDropCubit>().checkAnswer() : null,
          text: 'Check',
          isEnabled: canCheck,
        );
      },
    );
  }
}
