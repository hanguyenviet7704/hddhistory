part of '../../../../roleplay.dart';

class _ExpandedExerciseBody extends StatelessWidget {
  final QuestionEntity exercise;
  final int contentId;
  final int contentIndex;
  final bool readOnly;
  final ValueChanged<bool>? onAnswerChecked;
  final bool showResult;
  final bool isCorrect;
  final VoidCallback? onContinue;

  const _ExpandedExerciseBody({
    required this.exercise,
    required this.contentId,
    required this.contentIndex,
    this.readOnly = false,
    this.onAnswerChecked,
    this.showResult = false,
    this.isCorrect = false,
    this.onContinue,
  });

  void _handleAnswerChecked(BuildContext context, bool isCorrect) {
    _storeExerciseResult(context, isCorrect);
    onAnswerChecked?.call(isCorrect);
  }

  void _storeExerciseResult(BuildContext context, bool isCorrect) {
    final ExerciseResultEntity baseResult = switch (exercise.type) {
      QuestionTypeEnum.singleChoice => context.read<ChoiceCubit>().toExerciseResult(),
      QuestionTypeEnum.multipleChoice => context.read<ChoiceCubit>().toExerciseResult(),
      QuestionTypeEnum.dragAndDrop => context.read<DragAndDropCubit>().toExerciseResult(),
      QuestionTypeEnum.arrangeTheSequence => context.read<ArrangeTheSequenceCubit>().toExerciseResult(),
      QuestionTypeEnum.cuesPlacement => context.read<CuesPlacementCubit>().toExerciseResult(),
      QuestionTypeEnum.stressPlacement => context.read<MarkStressWordCubit>().toExerciseResult(),
      QuestionTypeEnum.speaking => context.read<SpeakingCubit>().toExerciseResult(),
    };

    context.read<RoleplayCubit>().setExerciseResult(
      contentId: contentId,
      contentIndex: contentIndex,
      result: baseResult.copyWith(passed: isCorrect),
    );
  }

  Widget _buildExerciseLessonBody(BuildContext context, QuestionTypeEnum questionType) {
    final onChecked = readOnly ? (_) {} : (bool isCorrect) => _handleAnswerChecked(context, isCorrect);
    return switch (questionType) {
      QuestionTypeEnum.singleChoice => SingleChoiceLessonBody(onAnswerChecked: onChecked),
      QuestionTypeEnum.multipleChoice => MultipleChoiceLessonBody(onAnswerChecked: onChecked),
      QuestionTypeEnum.dragAndDrop => DragAndDropLessonBody(onAnswerChecked: onChecked),
      QuestionTypeEnum.arrangeTheSequence => ArrangeTheSequenceLessonBody(onAnswerChecked: onChecked),
      QuestionTypeEnum.cuesPlacement => CuesPlacementLessonBody(onAnswerChecked: onChecked),
      QuestionTypeEnum.stressPlacement => MarkStressWordLessonBody(onAnswerChecked: onChecked),
      QuestionTypeEnum.speaking => SpeakingLessonBody(onAnswerChecked: onChecked),
    };
  }

  Widget _buildBottomButton(BuildContext context, Widget lessonBody) {
    return switch (lessonBody) {
      SingleChoiceLessonBody body => body.buildBottomButton(context),
      MultipleChoiceLessonBody body => body.buildBottomButton(context),
      DragAndDropLessonBody body => body.buildBottomButton(context),
      ArrangeTheSequenceLessonBody body => body.buildBottomButton(context),
      CuesPlacementLessonBody body => body.buildBottomButton(context),
      MarkStressWordLessonBody body => body.buildBottomButton(context),
      SpeakingLessonBody body => body.buildBottomButton(context),
      TheoryLessonBody body => body.buildBottomButton(context),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildContinueButton() {
    final isSpeaking = exercise.type == QuestionTypeEnum.speaking;
    final Color accentColor = isSpeaking || isCorrect ? AppCustomColor.successGreen : AppCustomColor.errorRed;

    return ExerciseContinueButton(
      onPressed: onContinue,
      text: t.exercise.exerciseSkipButton,
      backgroundColor: accentColor,
      textColor: AppCustomColor.textWhite,
      isEnabled: true,
    );
  }

  Widget _buildResultStatusRow() {
    final isSpeaking = exercise.type == QuestionTypeEnum.speaking;
    final Color accentColor = isSpeaking || isCorrect ? AppCustomColor.successGreen : AppCustomColor.errorRed;
    final String statusText = isSpeaking ? t.exercise.exerciseCompleteVoiceTask : (isCorrect ? t.exercise.exerciseFeedbackCorrectTitle : t.exercise.exerciseFeedbackIncorrectTitle);
    final Widget icon = isSpeaking || isCorrect ? AppAsset.icons.app.icTick.image(width: 24.w, height: 24.w) : AppAsset.icons.app.icClose.image(width: 24.w, height: 24.w);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          icon,
          8.horizontalSpace,
          AppText(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: AppStyle.text16.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget lessonBody = _buildExerciseLessonBody(context, exercise.type);
    Widget bottomButton = showResult ? _buildContinueButton() : _buildBottomButton(context, lessonBody);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Column(
        children: [
          if (showResult) ...[
            _buildResultStatusRow(),
            8.verticalSpace,
          ],
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  AbsorbPointer(
                    absorbing: readOnly,
                    child: lessonBody,
                  ),
                  60.verticalSpace,
                ],
              ),
            ),
          ),
          12.verticalSpace,
          bottomButton,
        ],
      ),
    );
  }
}
