part of '../../../exercise.dart';

class SpeakingLessonBody extends StatelessWidget {
  final Function(bool) onAnswerChecked;

  const SpeakingLessonBody({
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
        value: context.read<ChoiceCubit>(),
        child: BlocBuilder<ChoiceCubit, ChoiceState>(
          bloc: context.read<ChoiceCubit>(),
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
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SpeakingCubit, SpeakingState>(
      listenWhen: (previous, current) {
        // Trigger when submission status changes
        return previous.status != current.status;
      },
      listener: (context, state) {
        // Handle submission success
        if (state.status == SpeakingStatus.success) {
          // For speaking exercises, we don't check correct/incorrect immediately
          // Just move to the next question after successful submission
          onAnswerChecked(true);
          AppDI.injector.get<ExerciseCubit>().nextQuestion();
        }

        // Handle submission failure
        if (state.status == SpeakingStatus.failure && state.errorMessage != null) {
          // Show error message using EasyLoading or SnackBar
          EasyLoading.showError(state.errorMessage!);
        }
      },
      child: BlocBuilder<SpeakingCubit, SpeakingState>(
        builder: (context, state) {
          final currentQuestion = state.question;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display question document (images, audio, text, etc.)
              if (currentQuestion.document.isNotEmpty) ...[
                ChoiceDocumentWidget(documents: currentQuestion.document),
                16.verticalSpace,
              ],

              // Display instruction text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: AppText(
                  _getInstructionText(context, state.inputMode),
                  maxLines: 10,
                  style: AppStyle.text12.copyWith(
                    color: const Color(0xFF7F8EA4),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              16.verticalSpace,
            ],
          );
        },
      ),
    );
  }

  /// Get instruction text based on input mode
  String _getInstructionText(BuildContext context, SpeakingInputMode mode) {
    if (mode == SpeakingInputMode.recording) {
      return context.text.exerciseTapToSpeakButton;
    } else {
      return 'Type your answer in the text field below.'; // Can be replaced with localized text
    }
  }

  /// Build the bottom button for speaking questions
  Widget buildBottomButton(BuildContext context) {
    return const SpeakingBottomAction();
  }
}
