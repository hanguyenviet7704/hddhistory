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

  QuestionPayloadEntity get _payload => exercise.payloadOrLegacy;

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

    return switch (_payload) {
      QuestionSingleChoicePayloadEntity() => RoleplayAnswerLines(
        items: [_fallbackLine(correctOptions.firstOrNull)],
        style: answerTextStyle,
      ),
      QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => RoleplayAnswerLines(
        items: [_fallbackLine(_resolveNoCorrectSelectedAnswerText())],
        style: answerTextStyle,
      ),
      QuestionMultipleChoicePayloadEntity() => RoleplayAnswerLines(
        items: correctOptions.isEmpty ? [_fallbackLine(null)] : correctOptions,
        style: answerTextStyle,
      ),
      QuestionDragAndDropPayloadEntity() => RoleplayGapFillingAnswer(
        template: exercise.legacyTargetAreaFromPayload.text,
        answers: _resolveDragDropAnswers(correctOptions),
        baseStyle: answerTextStyle,
        highlightStyle: answerTextStyle.copyWith(
          color: AppCustomColor.successGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
      QuestionArrangeTheSequencePayloadEntity() => RoleplaySequenceAnswerList(
        items: sequenceAnswers.isEmpty ? [_fallbackLine(null)] : sequenceAnswers,
        style: answerTextStyle,
      ),
      QuestionStressPlacementPayloadEntity() || QuestionCuesPlacementPayloadEntity() => const SizedBox.shrink(),
      QuestionSpeakingPayloadEntity() => RoleplaySpeakingAnswer(
        recordAnswer: result.recordAnswer,
        textStyle: answerTextStyle,
      ),
      QuestionUnsupportedPayloadEntity() => RoleplayAnswerLines(
        items: [_fallbackLine(_resolveUnsupportedAnswerText())],
        style: answerTextStyle,
      ),
      _ => RoleplayAnswerLines(
        items: [_fallbackLine(_resolveUnsupportedAnswerText())],
        style: answerTextStyle,
      ),
    };
  }

  List<String> _resolveCorrectOptionTexts() {
    final options = exercise.legacyOptionsFromPayload.where((option) => option.isCorrect).toList();
    if (options.isNotEmpty) {
      return options.map((option) => option.textValue).where((text) => text.isNotEmpty).toList();
    }
    return exercise.legacyAnswersFromPayload.map((answer) => answer.correctAnswer.text).where((text) => text.isNotEmpty).toList();
  }

  List<String> _resolveDragDropAnswers(List<String> fallbackCorrectOptions) {
    final answers = exercise.legacyAnswersFromPayload;
    if (answers.isNotEmpty) {
      return answers.map((answer) => answer.correctAnswer.text).where((text) => text.isNotEmpty).toList();
    }
    if (fallbackCorrectOptions.isNotEmpty) return fallbackCorrectOptions;
    return [_fallbackLine(null)];
  }

  List<String> _resolveSequenceAnswers(List<String> fallbackCorrectOptions) {
    // Primary source: ordered answers from backend
    final answers = exercise.legacyAnswersFromPayload;
    if (answers.isNotEmpty) {
      return answers.map(_sequenceAnswerText).where((text) => text.isNotEmpty).toList();
    }

    // Fallback: use all options in their given order
    final orderedOptions = exercise.legacyOptionsFromPayload.map((option) => option.textValue).where((text) => text.isNotEmpty).toList();
    if (orderedOptions.isNotEmpty) return orderedOptions;

    return fallbackCorrectOptions;
  }

  String _sequenceAnswerText(AnswerEntity answer) {
    if (answer.correctAnswer.text.isNotEmpty) return answer.correctAnswer.text;

    final match = exercise.legacyOptionsFromPayload.firstWhere(
      (option) => option.id == answer.id,
      orElse: () => const OptionEntity(),
    );

    return match.textValue;
  }

  String _resolveNoCorrectSelectedAnswerText() {
    if (result.singleAnswer.labelText.isNotEmpty) return result.singleAnswer.labelText;
    final multipleFirst = result.multipleAnswer.firstOrNull;
    if (multipleFirst != null && multipleFirst.labelText.isNotEmpty) {
      return multipleFirst.labelText;
    }
    final fallbackOption = exercise.legacyOptionsFromPayload.firstOrNull;
    if (fallbackOption != null) return fallbackOption.textValue;
    return '';
  }

  String _resolveUnsupportedAnswerText() {
    if (result.singleAnswer.labelText.isNotEmpty) return result.singleAnswer.labelText;
    final multipleFirst = result.multipleAnswer.firstOrNull;
    if (multipleFirst != null && multipleFirst.labelText.isNotEmpty) return multipleFirst.labelText;
    return '';
  }

  String _fallbackLine(String? text) {
    if (text != null && text.isNotEmpty) return text;
    return '-';
  }
}
