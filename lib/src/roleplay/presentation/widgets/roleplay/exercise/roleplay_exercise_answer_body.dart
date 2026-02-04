part of '../../../../roleplay.dart';

class _RoleplayExerciseAnswerBody extends StatelessWidget {
  final QuestionEntity exercise;
  final ExerciseResultEntity result;
  final TextStyle labelTextStyle;
  final TextStyle answerTextStyle;
  final String answerLabel;

  const _RoleplayExerciseAnswerBody({
    required this.exercise,
    required this.result,
    required this.labelTextStyle,
    required this.answerTextStyle,
    required this.answerLabel,
  });

  @override
  Widget build(BuildContext context) {
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
            answerLabel.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: labelTextStyle,
          ),
          4.verticalSpace,
          _buildAnswerBody(),
        ],
      ),
    );
  }

  Widget _buildAnswerBody() {
    final correctOptions = _resolveCorrectOptionTexts();
    final sequenceAnswers = _resolveSequenceAnswers(correctOptions);

    switch (exercise.type) {
      case QuestionTypeEnum.singleChoice:
        return RoleplayAnswerLines(
          items: [correctOptions.firstOrNull ?? ''],
          style: answerTextStyle,
        );
      case QuestionTypeEnum.multipleChoice:
        return RoleplayAnswerLines(items: correctOptions, style: answerTextStyle);
      case QuestionTypeEnum.dragAndDrop:
        final gapAnswers = exercise.answer.isNotEmpty
            ? exercise.answer.map((answer) => answer.correctAnswer.text).toList()
            : correctOptions;
        return RoleplayGapFillingAnswer(
          template: exercise.targetArea.text,
          answers: gapAnswers,
          baseStyle: answerTextStyle,
          highlightStyle: answerTextStyle.copyWith(
            color: AppCustomColor.successGreen,
            fontWeight: FontWeight.w700,
          ),
        );
      case QuestionTypeEnum.arrangeTheSequence:
        return RoleplaySequenceAnswerList(items: sequenceAnswers, style: answerTextStyle);
      case QuestionTypeEnum.stressPlacement:
      case QuestionTypeEnum.cuesPlacement:
        return const SizedBox.shrink();
      case QuestionTypeEnum.speaking:
        return RoleplaySpeakingAnswer(
          recordAnswer: result.recordAnswer,
          textStyle: answerTextStyle,
        );
    }
  }

  List<String> _resolveCorrectOptionTexts() {
    final options = exercise.options.where((option) => option.isCorrect).toList();
    if (options.isNotEmpty) {
      return options.map((option) => option.textValue).where((text) => text.isNotEmpty).toList();
    }
    return exercise.answer
        .map((answer) => answer.correctAnswer.text)
        .where((text) => text.isNotEmpty)
        .toList();
  }

  List<String> _resolveSequenceAnswers(List<String> fallbackCorrectOptions) {
    // Primary source: ordered answers from backend
    if (exercise.answer.isNotEmpty) {
      return exercise.answer.map(_sequenceAnswerText).where((text) => text.isNotEmpty).toList();
    }

    // Fallback: use all options in their given order
    final orderedOptions = exercise.options
        .map((option) => option.textValue)
        .where((text) => text.isNotEmpty)
        .toList();
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
