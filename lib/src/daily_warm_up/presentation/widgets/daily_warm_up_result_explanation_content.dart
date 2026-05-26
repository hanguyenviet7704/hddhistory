part of '../../daily_warm_up.dart';

class DailyWarmUpResultExplanationContent extends StatelessWidget {
  const DailyWarmUpResultExplanationContent({
    super.key,
    required this.result,
    required this.question,
    required this.explanationText,
  });

  final DailyWarmUpAnswerResultEntity result;
  final QuestionEntity? question;
  final String explanationText;

  @override
  Widget build(BuildContext context) {
    final answer = _correctAnswerWidget(context);
    if (answer == null) return _buildChoiceStyleExplanation(context);

    return _scrollablePanel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            context.l10n.exercise.exerciseFeedbackCorrectAnswer,
            style: AppStyle.textBold14.copyWith(
              color: const Color(0xFF3A9377),
              height: 1.75,
            ),
          ),
          4.verticalSpace,
          answer,
          16.verticalSpace,
          Container(height: 1, width: double.infinity, color: const Color(0xFFE3E8EF)),
          16.verticalSpace,
          _DailyWarmUpExplanationCard(explanationText: explanationText),
        ],
      ),
    );
  }

  Widget _buildChoiceStyleExplanation(BuildContext context) {
    return _scrollablePanel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            context.l10n.exercise.exerciseExplanationTitle,
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D121C),
            ),
          ),
          16.verticalSpace,
          AppText(
            explanationText,
            maxLines: 100,
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF364152),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scrollablePanel({required BuildContext context, required Widget child}) {
    return Container(
      key: const ValueKey('daily-warm-up-result-explanation'),
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.55),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      color: Colors.white,
      child: SingleChildScrollView(child: child),
    );
  }

  Widget? _correctAnswerWidget(BuildContext context) {
    final currentQuestion = question;
    if (currentQuestion == null) return null;
    return switch (currentQuestion.typedPayload) {
      QuestionArrangeTheSequencePayloadEntity() => _arrangeAnswers(),
      QuestionDragAndDropPayloadEntity(:final targetArea) => _sentenceAnswer(_dragSentenceSpans(targetArea.text, _correctOptionLabels(currentQuestion))),
      QuestionCuesPlacementPayloadEntity(:final targetArea) => _sentenceAnswer(_positionSentenceSpans(_targetWords(targetArea), result.correctIndices, cueSuffix: ' (pause)')),
      QuestionStressPlacementPayloadEntity(:final targetArea) => _sentenceAnswer(
        _positionSentenceSpans(_targetWords(targetArea), result.correctIndices, uppercaseMarkedWords: true),
      ),
      _ => null,
    };
  }

  Widget _arrangeAnswers() {
    final labels = _correctOptionLabels(question!);
    if (labels.isEmpty) return const SizedBox.shrink();
    return Column(
      children: labels
          .map((label) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: AppText(
                  label,
                  maxLines: 10,
                  style: AppStyle.text14.copyWith(
                    color: const Color(0xFF364152),
                    height: 1.75,
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _sentenceAnswer(List<InlineSpan> spans) {
    return RichText(
      text: TextSpan(
        children: spans,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, height: 1.5),
      ),
    );
  }

  List<String> _correctOptionLabels(QuestionEntity currentQuestion) {
    final optionsById = {for (final option in questionRuntimeOptions(currentQuestion)) option.id: option.labelText};
    final labels = result.correctOptionIds.map((id) => optionsById[id]?.trim() ?? '').where((label) => label.isNotEmpty).toList(growable: false);
    if (labels.isNotEmpty) return labels;
    return questionRuntimeAnswers(currentQuestion).map((answer) => answer.correctAnswer.text.trim()).where((label) => label.isNotEmpty).toList(growable: false);
  }

  List<InlineSpan> _dragSentenceSpans(String targetArea, List<String> answers) {
    final spans = <InlineSpan>[];
    final parts = targetArea.split('___');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) spans.add(_textSpan(parts[i], isHighlighted: false));
      if (i < answers.length) spans.add(_textSpan(answers[i], isHighlighted: true));
    }
    return spans;
  }

  List<InlineSpan> _positionSentenceSpans(List<String> words, List<int> correctIndices, {String cueSuffix = '', bool uppercaseMarkedWords = false}) {
    final correct = correctIndices.toSet();
    final spans = <InlineSpan>[];
    for (var i = 0; i < words.length; i++) {
      final isHighlighted = correct.contains(i);
      final word = isHighlighted && uppercaseMarkedWords ? words[i].toUpperCase() : words[i];
      spans.add(_textSpan('$word${isHighlighted ? cueSuffix : ''}', isHighlighted: isHighlighted));
      if (i < words.length - 1) spans.add(const TextSpan(text: ' '));
    }
    return spans;
  }

  TextSpan _textSpan(String text, {required bool isHighlighted}) {
    return TextSpan(
      text: text,
      style: TextStyle(
        color: isHighlighted ? const Color(0xFF0D121C) : const Color(0xFF7F8EA4),
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
    );
  }
}
