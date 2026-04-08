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

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 68.h, 20.w, 20.h + MediaQuery.viewPaddingOf(context).bottom),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      questionText,
                      maxLines: 6,
                      style: AppStyle.textBold20.copyWith(
                        color: AppCustomColor.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    if (state.currentQuestionIsMultipleChoice) ...[
                      8.verticalSpace,
                      AppText(
                        context.l10n.videoLesson.selectAllThatApplyLabel,
                        style: AppStyle.text12.copyWith(
                          color: AppCustomColor.textTertiary,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                    16.verticalSpace,
                    if (isSupported)
                      ...state.currentQuestionOptions.asMap().entries.map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: _VideoLessonQuestionOptionCard(
                            label: entry.value.labelText,
                            selected: state.currentQuestionIsMultipleChoice
                                ? state.currentSelectedAnswerIndices.contains(entry.key)
                                : state.currentSelectedAnswerIndex == entry.key,
                            onTap: () => onAnswerTap(entry.key),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: AppText(
                          context.l10n.videoLesson.unsupportedQuestionMessage,
                          maxLines: 6,
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
            24.verticalSpace,
            AppButton.primary(
              onPressed: state.currentQuestionCanSubmit ? onSubmit : null,
              disabled: !state.currentQuestionCanSubmit,
              fullWidthBtn: true,
              height: 54.h,
              borderRadius: BorderRadius.circular(1000.r),
              child: AppText(
                isSupported ? context.l10n.videoLesson.checkQuestionButton : context.l10n.videoLesson.continueWatchingButton,
                style: AppStyle.textBold16.copyWith(color: Colors.white),
              ),
            ),
          ],
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF),
            width: 2,
          ),
        ),
        child: AppText(
          label,
          maxLines: 4,
          style: AppStyle.text14.copyWith(
            color: AppCustomColor.textSecondary,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            height: 1.75,
          ),
        ),
      ),
    );
  }
}
