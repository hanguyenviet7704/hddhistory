part of '../../video_lesson.dart';

class VideoLessonQuestionResultSheet extends StatelessWidget {
  const VideoLessonQuestionResultSheet({
    super.key,
    required this.state,
    required this.onContinue,
  });

  final VideoLessonState state;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    final result = state.currentQuestionResult;
    if (question == null || result == null) return const SizedBox.shrink();

    final explanationText = _resolveQuestionExplanation(question, result);
    final questionText = question.questionText == 'No question text' ? question.speechBubble.text : question.questionText;

    return _VideoLessonBlockingOverlayLayout(
      card: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.62),
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 22.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      color: _resultColor(result),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      result.isSupported
                          ? result.isCorrect
                                ? Icons.check_rounded
                                : Icons.close_rounded
                          : Icons.info_outline_rounded,
                      size: 16.r,
                      color: Colors.white,
                    ),
                  ),
                  10.horizontalSpace,
                  AppText(
                    _resultTitle(context, result),
                    style: AppStyle.textBold16.copyWith(
                      color: _resultColor(result),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              18.verticalSpace,
              AppText(
                questionText,
                maxLines: 6,
                style: AppStyle.textBold20.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.45,
                ),
              ),
              18.verticalSpace,
              ...state.currentQuestionOptions.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _VideoLessonQuestionResultOptionCard(
                    label: entry.value.labelText,
                    state: _resolveAnswerState(
                      index: entry.key,
                      option: entry.value,
                      question: question,
                      result: result,
                    ),
                  ),
                ),
              ),
              if (explanationText.isNotEmpty) ...[
                10.verticalSpace,
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: 18.h),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppCustomColor.borderDefault, width: 1.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 20.r,
                            color: const Color(0xFF175CD3),
                          ),
                          8.horizontalSpace,
                          AppText(
                            context.l10n.videoLesson.explanationTitle,
                            style: AppStyle.textBold16.copyWith(
                              color: const Color(0xFF175CD3),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      8.verticalSpace,
                      AppText(
                        explanationText,
                        maxLines: 12,
                        style: AppStyle.text14.copyWith(
                          color: AppCustomColor.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      cta: AppButton.primary(
        onPressed: onContinue,
        fullWidthBtn: true,
        height: 62.h,
        borderRadius: BorderRadius.circular(1000.r),
        child: AppText(
          context.l10n.videoLesson.continueWatchingButton,
          style: AppStyle.textBold16.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

enum _VideoLessonResultAnswerState { neutral, correct, incorrect, correctMissed }

class _VideoLessonQuestionResultOptionCard extends StatelessWidget {
  const _VideoLessonQuestionResultOptionCard({
    required this.label,
    required this.state,
  });

  final String label;
  final _VideoLessonResultAnswerState state;

  @override
  Widget build(BuildContext context) {
    final style = switch (state) {
      _VideoLessonResultAnswerState.correct || _VideoLessonResultAnswerState.correctMissed => (
        background: AppCustomColor.backgroundSuccess,
        border: AppCustomColor.successGreen,
        icon: Icons.check_rounded,
        iconColor: Colors.white,
        iconBackground: AppCustomColor.successGreen,
      ),
      _VideoLessonResultAnswerState.incorrect => (
        background: const Color(0xFFFFF1F3),
        border: const Color(0xFFF04438),
        icon: Icons.close_rounded,
        iconColor: Colors.white,
        iconBackground: const Color(0xFFF04438),
      ),
      _ => (
        background: Colors.white,
        border: const Color(0xFFE3E8EF),
        icon: null,
        iconColor: Colors.transparent,
        iconBackground: Colors.transparent,
      ),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: style.border, width: state == _VideoLessonResultAnswerState.neutral ? 1.5 : 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              label,
              maxLines: 4,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textSecondary,
                fontWeight: state == _VideoLessonResultAnswerState.neutral ? FontWeight.w400 : FontWeight.w600,
                height: 1.6,
              ),
            ),
          ),
          if (style.icon != null) ...[
            10.horizontalSpace,
            Container(
              width: 24.r,
              height: 24.r,
              decoration: BoxDecoration(
                color: style.iconBackground,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                style.icon,
                size: 14.r,
                color: style.iconColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _resultColor(VideoLessonQuestionResult result) {
  if (!result.isSupported) return const Color(0xFF175CD3);
  return result.isCorrect ? AppCustomColor.successGreen : const Color(0xFFF04438);
}

String _resultTitle(BuildContext context, VideoLessonQuestionResult result) {
  if (!result.isSupported) return context.l10n.videoLesson.unsupportedQuestionTitle;
  return result.isCorrect ? context.l10n.videoLesson.correctAnswerTitle : context.l10n.videoLesson.incorrectAnswerTitle;
}

String _resolveQuestionExplanation(QuestionEntity question, VideoLessonQuestionResult result) {
  if (result.noCorrectDocumentGroupId != null && result.noCorrectDocumentGroupId!.isNotEmpty) {
    final documentGroup = resolveNoCorrectAnswerDocumentGroupById(
      question: question,
      groupId: result.noCorrectDocumentGroupId!,
    );
    if (documentGroup != null) {
      final text = documentGroup.documents.map((item) => item.data.content.text.trim()).where((item) => item.isNotEmpty).join('\n\n');
      if (text.isNotEmpty) return text;
    }
  }
  return question.explanation.text.trim();
}

_VideoLessonResultAnswerState _resolveAnswerState({
  required int index,
  required OptionEntity option,
  required QuestionEntity question,
  required VideoLessonQuestionResult result,
}) {
  if (!result.isSupported) return _VideoLessonResultAnswerState.neutral;

  final isSelected = result.selectedAnswerIndices.contains(index) || result.selectedAnswerIndex == index;
  final isNoCorrect = question.typedPayload is QuestionSingleChoiceNoCorrectAnswerPayloadEntity;
  final isCorrect = isNoCorrect ? result.selectedAnswerIndex == index : option.isCorrect;

  if (isCorrect && isSelected) return _VideoLessonResultAnswerState.correct;
  if (isCorrect && !isSelected && question.typedPayload is QuestionMultipleChoicePayloadEntity) {
    return _VideoLessonResultAnswerState.correctMissed;
  }
  if (isSelected && !isCorrect) return _VideoLessonResultAnswerState.incorrect;
  return _VideoLessonResultAnswerState.neutral;
}
