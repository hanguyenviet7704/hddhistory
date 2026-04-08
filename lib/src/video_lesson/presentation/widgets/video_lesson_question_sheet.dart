part of '../../video_lesson.dart';

class VideoLessonQuestionSheet extends StatelessWidget {
  const VideoLessonQuestionSheet({
    super.key,
    required this.state,
    required this.onAnswerTap,
    required this.onSubmit,
  });

  final VideoLessonState state;
  final ValueChanged<int> onAnswerTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final isSupported = state.currentQuestionIsSupported;
    final questionText = question.questionText == 'No question text' ? question.speechBubble.text : question.questionText;

    return _VideoLessonBlockingOverlayLayout(
      pinCtaToBottom: true,
      card: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.56),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(
                questionText,
                maxLines: 6,
                textAlign: TextAlign.center,
                style: AppStyle.textBold20.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.45,
                ),
              ),
              if (state.currentQuestionIsMultipleChoice) ...[
                10.verticalSpace,
                AppText(
                  context.l10n.videoLesson.selectAllThatApplyLabel,
                  textAlign: TextAlign.center,
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.textTertiary,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
              18.verticalSpace,
              if (isSupported)
                ...state.currentQuestionOptions.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _VideoLessonAnimatedEntrance(
                      beginOffset: Offset(0, 14.h),
                      beginScale: 0.98,
                      delay: Duration(milliseconds: 70 + (entry.key * 40)),
                      child: _VideoLessonQuestionOptionCard(
                        label: entry.value.labelText,
                        selected: state.currentQuestionIsMultipleChoice ? state.currentSelectedAnswerIndices.contains(entry.key) : state.currentSelectedAnswerIndex == entry.key,
                        onTap: () => onAnswerTap(entry.key),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppCustomColor.backgroundGray,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: AppText(
                    context.l10n.videoLesson.unsupportedQuestionMessage,
                    maxLines: 6,
                    textAlign: TextAlign.center,
                    style: AppStyle.text14.copyWith(
                      color: AppCustomColor.textSecondary,
                      height: 1.75,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      cta: AppButton.primary(
        onPressed: state.currentQuestionCanSubmit ? onSubmit : null,
        disabled: !state.currentQuestionCanSubmit,
        fullWidthBtn: true,
        height: 62.h,
        borderRadius: BorderRadius.circular(1000.r),
        child: AppText(
          isSupported ? context.l10n.videoLesson.checkQuestionButton : context.l10n.videoLesson.continueWatchingButton,
          style: AppStyle.textBold16.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _VideoLessonQuestionOptionCard extends StatelessWidget {
  const _VideoLessonQuestionOptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _VideoLessonPressableScale(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: _videoLessonFastAnimationDuration,
        curve: _videoLessonEntranceCurve,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: AppText(
          label,
          maxLines: 4,
          style: AppStyle.text14.copyWith(
            color: AppCustomColor.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
