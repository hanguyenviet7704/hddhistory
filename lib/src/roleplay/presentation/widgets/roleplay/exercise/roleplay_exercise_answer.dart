part of '../../../../roleplay.dart';

class RoleplayExerciseAnswerCard extends StatelessWidget {
  final QuestionEntity exercise;

  const RoleplayExerciseAnswerCard({
    super.key,
    required this.exercise,
  });

  TextStyle get _questionTextStyle => AppStyle.text14.copyWith(
    color: AppCustomColor.textSecondary,
    fontWeight: FontWeight.w700,
    height: 1.75,
  );

  TextStyle get _labelTextStyle => AppStyle.text12.copyWith(
    color: AppCustomColor.textTertiary,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  TextStyle get _answerTextStyle => AppStyle.text14.copyWith(
    color: AppCustomColor.textPrimary,
    fontWeight: FontWeight.w500,
    height: 1.75,
  );

  bool get _showsStatusHeader => exercise.type != QuestionTypeEnum.speaking;

  String get _answerLabel => exercise.type == QuestionTypeEnum.speaking ? t.exercise.exerciseYourAnswer : t.exercise.exerciseAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppCustomColor.roleplayAnswerBackground,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(exercise.isCompleted),
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 8.h),
            child: _buildAnswerCard(exercise.result),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isCorrect) {
    if (_showsStatusHeader) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoleplayStatusRow(isCorrect: isCorrect),
                _buildChevron(size: 18.w),
              ],
            ),
            4.verticalSpace,
            AppText(
              exercise.questionText,
              maxLines: 5,
              style: _questionTextStyle,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: AppText(
              exercise.questionText,
              maxLines: 5,
              style: _questionTextStyle,
            ),
          ),
          8.horizontalSpace,
          _buildChevron(size: 24.w),
        ],
      ),
    );
  }

  Widget _buildChevron({double size = 18}) {
    return Icon(
      Icons.chevron_right,
      size: size,
      color: AppCustomColor.textTertiary,
    );
  }

  Widget _buildAnswerCard(ExerciseResultEntity result) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 3.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            _answerLabel.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: _labelTextStyle,
          ),
          4.verticalSpace,
          _buildAnswerBody(result),
        ],
      ),
    );
  }

  Widget _buildAnswerBody(ExerciseResultEntity result) {
    final correctOptions = _resolveCorrectOptionTexts();
    final sequenceAnswers = _resolveSequenceAnswers(correctOptions);

    switch (exercise.type) {
      case QuestionTypeEnum.singleChoice:
        return RoleplayAnswerLines(
          items: [correctOptions.firstOrNull ?? ''],
          style: _answerTextStyle,
        );
      case QuestionTypeEnum.multipleChoice:
        return RoleplayAnswerLines(items: correctOptions, style: _answerTextStyle);
      case QuestionTypeEnum.dragAndDrop:
        final gapAnswers = exercise.answer.isNotEmpty ? exercise.answer.map((answer) => answer.correctAnswer.text).toList() : correctOptions;
        return RoleplayGapFillingAnswer(
          template: exercise.targetArea.text,
          answers: gapAnswers,
          baseStyle: _answerTextStyle,
          highlightStyle: _answerTextStyle.copyWith(
            color: AppCustomColor.successGreen,
            fontWeight: FontWeight.w700,
          ),
        );
      case QuestionTypeEnum.arrangeTheSequence:
        return RoleplaySequenceAnswerList(items: sequenceAnswers, style: _answerTextStyle);
      case QuestionTypeEnum.stressPlacement:
      case QuestionTypeEnum.cuesPlacement:
        return const SizedBox.shrink();
      case QuestionTypeEnum.speaking:
        return RoleplaySpeakingAnswer(recordAnswer: result.recordAnswer, textStyle: _answerTextStyle);
    }
  }

  List<String> _resolveCorrectOptionTexts() {
    final options = exercise.options.where((option) => option.isCorrect).toList();
    if (options.isNotEmpty) {
      return options.map((option) => option.textValue).where((text) => text.isNotEmpty).toList();
    }
    return exercise.answer.map((answer) => answer.correctAnswer.text).where((text) => text.isNotEmpty).toList();
  }

  List<String> _resolveSequenceAnswers(List<String> fallbackCorrectOptions) {
    // Primary source: ordered answers from backend
    if (exercise.answer.isNotEmpty) {
      return exercise.answer.map(_sequenceAnswerText).where((text) => text.isNotEmpty).toList();
    }

    // Fallback: use all options in their given order
    final orderedOptions = exercise.options.map((option) => option.textValue).where((text) => text.isNotEmpty).toList();
    if (orderedOptions.isNotEmpty) return orderedOptions;

    return fallbackCorrectOptions;
  }

  String _sequenceAnswerText(AnswerEntity answer) {
    if (answer.correctAnswer.text.isNotEmpty) return answer.correctAnswer.text;

    final match = exercise.options.firstWhere(
      (option) => option.id == answer.id,
      orElse: () => const OptionEntity(),
    );

    return match.textValue;
  }
}

class _RoleplayStatusRow extends StatelessWidget {
  final bool isCorrect;
  const _RoleplayStatusRow({required this.isCorrect});

  Color get statusColor => isCorrect ? AppCustomColor.successGreen : AppCustomColor.errorRed;
  String get statusText => isCorrect ? t.exercise.exerciseFeedbackRight : t.exercise.exerciseFeedbackNotTrue;
  Widget get icon => isCorrect ? AppAsset.icons.app.icTick.image(width: 18.w, height: 18.w) : AppAsset.icons.app.icClose.image(width: 18.w, height: 18.w);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        8.horizontalSpace,
        AppText(
          statusText,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppStyle.text14.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w700,
            height: 1.75,
          ),
        ),
      ],
    );
  }
}
