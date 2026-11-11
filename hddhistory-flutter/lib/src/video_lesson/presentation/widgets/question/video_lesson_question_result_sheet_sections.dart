part of '../../../video_lesson.dart';

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
        iconAsset: AppAsset.icons.app.icTick,
      ),
      _VideoLessonResultAnswerState.incorrect => (
        background: const Color(0xFFFFF1F3),
        border: const Color(0xFFF04438),
        iconAsset: AppAsset.icons.app.icClose,
      ),
      _ => (
        background: Colors.white,
        border: const Color(0xFFE3E8EF),
        iconAsset: null,
      ),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: style.border,
          width: state == _VideoLessonResultAnswerState.neutral ? 1.5 : 2,
        ),
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
          if (style.iconAsset != null) ...[
            10.horizontalSpace,
            _VideoLessonAnimatedEntrance(
              beginScale: 0.72,
              duration: _videoLessonMediumAnimationDuration,
              curve: _videoLessonSpringCurve,
              child: style.iconAsset!.image(
                width: 24.r,
                height: 24.r,
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
  if (!result.isSupported) {
    return context.l10n.videoLesson.unsupportedQuestionTitle;
  }
  return result.isCorrect ? context.l10n.videoLesson.correctAnswerTitle : context.l10n.videoLesson.incorrectAnswerTitle;
}

String _resolveQuestionExplanation(
  QuestionEntity question,
  VideoLessonQuestionResult result,
) {
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
