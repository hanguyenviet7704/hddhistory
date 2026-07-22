part of '../../../lesson.dart';

class TheoryLessonBody extends LessonBodyWidget {
  final Function(bool) onAnswerChecked;

  const TheoryLessonBody({
    super.key,
    required this.onAnswerChecked,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<TheoryCubit, TheoryState>(
      listenWhen: (previous, current) {
        // Only trigger when hasChecked changes from false to true
        return !previous.hasChecked && current.hasChecked;
      },
      listener: (context, state) {
        onAnswerChecked(state.isCorrect);
      },
      child: BlocBuilder<TheoryCubit, TheoryState>(
        builder: (context, state) {
          final currentDocument = state.currentDocument;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentDocument.document.isNotEmpty) ...[
                DocumentWidget(
                  documents: currentDocument.document,
                  // Theory content card is frosted glass over a custom study
                  // background (design), unlike the solid exercise cards.
                  frosted: true,
                  selectedExplanationOptionKeys: state.selectedExplanationOptionKeys,
                  onExplanationSelectionChanged: (contentDocumentIndex, optionKey) {
                    context.read<TheoryCubit>().selectExplanationOption(
                      contentDocumentIndex: contentDocumentIndex,
                      optionKey: optionKey,
                    );
                  },
                ),
                12.verticalSpace,
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<TheoryCubit, TheoryState>(
      builder: (context, state) {
        return ExerciseContinueButton(
          onPressed: state.canContinue
              ? () {
                  final trackingData = KeypointTrackingData.fromContext();
                  if (trackingData != null) {
                    AppService.instance.appTrackingService.trackKeypointTheoryContinueClick(trackingData);
                  }
                  context.read<TheoryCubit>().nextDocument();
                }
              : null,
          text: context.l10n.common.kContinue,
          isEnabled: state.canContinue,
        );
      },
    );
  }
}
