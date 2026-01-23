part of '../../../lesson.dart';

class TheoryLessonBody extends StatelessWidget {
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
                DocumentWidget(documents: currentDocument.document),
                12.verticalSpace,
              ],
            ],
          );
        },
      ),
    );
  }

  /// Build the bottom button for theory questions
  Widget buildBottomButton(BuildContext context) {
    return BlocBuilder<TheoryCubit, TheoryState>(
      builder: (context, state) {
        return ExerciseContinueButton(
          onPressed: () {
            final trackingData = KeypointTrackingData.fromContext();
            if (trackingData != null) {
              AppService.instance.appTrackingService.trackKeypointTheoryContinueClick(trackingData);
            }
            context.read<TheoryCubit>().nextDocument();
          },
          text: context.text.common.kContinue,
          isEnabled: true,
        );
      },
    );
  }
}
