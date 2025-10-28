part of '../../../exercise.dart';

class CuesPlacementLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const CuesPlacementLessonBody({
    super.key,
    required this.onAnswerChecked,
  });

  void _showResultBottomSheet(BuildContext context, ResultType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp))),
      routeSettings: const RouteSettings(name: RouteNamed.exerciseResultPopup),
      builder: (modalContext) => BlocProvider.value(
        value: context.read<CuesPlacementCubit>(),
        child: BlocBuilder<CuesPlacementCubit, CuesPlacementState>(
          bloc: context.read<CuesPlacementCubit>(),
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
                      onTap: () => context.read<CuesPlacementCubit>().toggleExplanation(),
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
                  child: CuesPlacementResultBottomSheet(
                    type: type,
                    showExplanation: state.showExplanation,
                    explanationText: state.question.explanation,
                    words: state.words,
                    placedMarks: state.placedMarks,
                    correctPositions: state.correctPositions,
                    optionsById: {
                      for (var option in state.question.options) option.id: option,
                    },
                    onContinue: () {
                      modalContext.back();
                    },
                    onExplain: () {
                      context.read<CuesPlacementCubit>().toggleExplanation();
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
    return BlocListener<CuesPlacementCubit, CuesPlacementState>(
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
      child: BlocBuilder<CuesPlacementCubit, CuesPlacementState>(
        builder: (context, state) {
          final currentQuestion = state.question;
          final words = state.words;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.document.any((document) => document.dataAvailable)) ...[
                ChoiceDocumentWidget(documents: currentQuestion.document),
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
              // Words with drop zones in styled container
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
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
                  runSpacing: 6.h,
                  children: List.generate(
                    words.length,
                    (index) {
                      final placedMarkId = state.placedMarks[index];
                      final placedMark = placedMarkId != null
                          ? currentQuestion.options.firstWhere(
                              (opt) => opt.id == placedMarkId,
                              orElse: () => const OptionEntity(),
                            )
                          : null;
                      return CuesPlacementWordWithDropZone(
                        word: words[index],
                        wordIndex: index,
                        placedMark: placedMark,
                        markState: state.getPauseMarkState(index),
                        hasChecked: state.hasChecked,
                        onAcceptMark: (wordIndex, data) {
                          if (data.fromWordIndex != null) {
                            // Moving from another position
                            context.read<CuesPlacementCubit>().movePauseMark(
                              data.fromWordIndex!,
                              wordIndex,
                            );
                          } else {
                            // Placing from available pool
                            context.read<CuesPlacementCubit>().placePauseMark(
                              wordIndex,
                              data.optionId,
                            );
                          }
                        },
                        onRemoveMark: (wordIndex) {
                          context.read<CuesPlacementCubit>().removePauseMark(wordIndex);
                        },
                      );
                    },
                  ),
                ),
              ),
              24.verticalSpace,
              // Available pause marks pool
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: CuesPlacementAvailableMarks(
                  availableOptions: state.availableOptions,
                  totalCount: state.totalMarksCount,
                  availableCount: state.availableMarksCount,
                  onAcceptReturn: (data) {
                    if (data.fromWordIndex != null) {
                      context.read<CuesPlacementCubit>().removePauseMark(data.fromWordIndex!);
                    }
                  },
                ),
              ),
              20.verticalSpace,
            ],
          );
        },
      ),
    );
  }

  /// Build the bottom button for cues placement questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<CuesPlacementCubit, CuesPlacementState>(
      builder: (context, state) {
        final canCheck = state.placedMarks.isNotEmpty && !state.hasChecked;

        return ExerciseContinueButton(
          onPressed: canCheck ? () => context.read<CuesPlacementCubit>().checkAnswer() : null,
          text: 'Check',
          isEnabled: canCheck,
        );
      },
    );
  }
}
