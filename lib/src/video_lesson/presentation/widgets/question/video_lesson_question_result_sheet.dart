part of '../../../video_lesson.dart';

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
      pinCtaToBottom: true,
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
                  _VideoLessonAnimatedEntrance(
                    beginScale: 0.72,
                    duration: _videoLessonMediumAnimationDuration,
                    curve: _videoLessonSpringCurve,
                    child: result.isSupported
                        ? (result.isCorrect
                              ? AppAsset.icons.app.icTick.image(
                                  width: 28.r,
                                  height: 28.r,
                                )
                              : AppAsset.icons.app.icClose.image(
                                  width: 28.r,
                                  height: 28.r,
                                ))
                        : Icon(
                            Icons.info_outline_rounded,
                            size: 24.r,
                            color: const Color(0xFF175CD3),
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
                  child: _VideoLessonAnimatedEntrance(
                    beginOffset: Offset(0, 14.h),
                    beginScale: 0.98,
                    delay: Duration(milliseconds: 80 + (entry.key * 35)),
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
                          AppAsset.icons.app.icTag.image(
                            width: 20.r,
                            height: 20.r,
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
