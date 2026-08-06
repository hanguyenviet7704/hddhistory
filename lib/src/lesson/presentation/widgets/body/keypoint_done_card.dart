part of '../../../lesson.dart';

/// Terminal card of the unified keypoint swipe screen — the design's peek card
/// (`_Keypoint Swipe Lab` → `c.isPeek`): the keypoint restated as a white quote
/// card, a practice entry beneath it, and Continue at the bottom.
///
/// This card used to be a checkmark visible for a frame or two:
/// [LessonCubit.completeCurrentKeypoint] navigated to [KeypointCompleteRoute]
/// the instant the last real card finished, covering it. Completion still fires
/// exactly then (progress written, Live Activity updated, `completionOrigin`
/// set — nothing about WHAT completing means changed), but navigation now waits
/// for Continue here, because this card carries the keypoint's practice: the
/// keypoint's own exercises, played as a swipe quiz ([KeypointQuizPage]).
/// Practice hangs off the keypoint — the same rule the server uses to derive a
/// habit's practice — so this is where it is offered, while the keypoint is
/// still on screen. Readers who want none of it tap Continue and get the exact
/// old flow.
///
/// The explicit completion call below is a fallback for the one path where
/// nothing else would have triggered completion: a keypoint with no content at
/// all.
class KeypointDoneCard extends StatefulWidget {
  const KeypointDoneCard({super.key});

  @override
  State<KeypointDoneCard> createState() => _KeypointDoneCardState();
}

class _KeypointDoneCardState extends State<KeypointDoneCard> {
  @override
  void initState() {
    super.initState();
    AppHaptic.celebrate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lessonCubit = context.read<LessonCubit>();
      if (lessonCubit.state.completionOrigin == LessonCompletionOrigin.none) {
        lessonCubit.completeCurrentKeypoint();
      }
    });
  }

  /// The keypoint's playable exercise questions — what [KeypointQuizPage] will
  /// deal as cards. Same filter the server's habit-practice derivation applies:
  /// `type: exercise` items with questions, in authored order.
  List<QuestionEntity> _practiceQuestions(LessonState lessonState) {
    return lessonState.pageData.items
        .where((item) => item.type == LearningItemType.exercise)
        .expand((item) => item.mainQuestions)
        .where(QuizCardAnswer.isPlayableQuestion)
        .toList();
  }

  void _openPractice(BuildContext context, List<QuestionEntity> questions) {
    if (questions.isEmpty) return;
    AppHaptic.select();
    final title = context.read<CourseLessonCubit>().state.currentTitle;
    KeypointQuizPage.push(context, title: title, questions: questions);
  }

  @override
  Widget build(BuildContext context) {
    final lessonState = context.watch<LessonCubit>().state;
    final courseLessonState = context.watch<CourseLessonCubit>().state;
    final keypoint = courseLessonState.resolvedCurrentKeypoint;
    final keypointTitle = keypoint.title.text.isNotEmpty ? keypoint.title.text : courseLessonState.selectedLesson.title.text;
    final lessonTitle = courseLessonState.selectedLesson.title.text;
    final imageUrl = keypoint.image.isNotEmpty ? keypoint.image : courseLessonState.selectedLesson.image;
    final questions = _practiceQuestions(lessonState);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        children: [
          const Spacer(),
          GestureDetector(
            onTap: () => _openPractice(context, questions),
            child: _quoteCard(context, keypointTitle: keypointTitle, lessonTitle: lessonTitle, imageUrl: imageUrl),
          ),
          if (questions.isNotEmpty) ...[
            16.verticalSpace,
            _practiceHint(context, questions),
          ],
          const Spacer(),
          _continueButton(context),
          12.verticalSpace,
        ],
      ),
    );
  }

  /// The design's white quote card: 290×(3:4), a giant pale quote mark behind
  /// the keypoint title, the lesson it belongs to as the uppercase source line,
  /// and the keypoint's illustration in the lower-right corner.
  Widget _quoteCard(BuildContext context, {required String keypointTitle, required String lessonTitle, required String imageUrl}) {
    return Container(
      width: 290.w,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(color: const Color(0x1A141828), blurRadius: 34, offset: const Offset(0, 14)),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26.r),
          child: Stack(
            children: [
              Positioned(
                top: 6.h,
                left: 14.w,
                child: Text(
                  '“',
                  style: TextStyle(
                    fontFamily: AppFont.poppins,
                    fontWeight: FontWeight.w700,
                    fontSize: 130.sp,
                    height: 1,
                    color: AppCustomColor.kpPeekQuoteMark,
                  ),
                ),
              ),
              if (imageUrl.isNotEmpty)
                Positioned(
                  right: 20.w,
                  bottom: 20.h,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 92.w,
                    height: 118.h,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                // Bottom inset keeps the text clear of the illustration corner —
                // the design reserves the card's lower strip for it.
                padding: EdgeInsets.fromLTRB(26.w, 30.h, 26.w, 108.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      keypointTitle,
                      maxLines: 5,
                      // Design 21/700 — the app scale has no 21, and this card is
                      // a design set piece, so it keeps the exact value.
                      style: TextStyle(
                        fontFamily: AppFont.mulish,
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.28,
                        color: AppCustomColor.textPrimary,
                      ),
                    ),
                    11.verticalSpace,
                    Container(
                      width: 28.w,
                      height: 2.h,
                      decoration: BoxDecoration(
                        color: AppCustomColor.kpPeekDivider,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    if (lessonTitle.isNotEmpty) ...[
                      8.verticalSpace,
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 203.w),
                        child: AppText(
                          lessonTitle.toUpperCase(),
                          maxLines: 3,
                          // Design 8.5/700, .08em tracking — exact values, see above.
                          style: TextStyle(
                            fontFamily: AppFont.mulish,
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                            letterSpacing: 8.5 * 0.08,
                            color: AppCustomColor.kpPeekSource,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The design's tap hint under the card, repurposed for what tapping does
  /// here: practise this keypoint.
  Widget _practiceHint(BuildContext context, List<QuestionEntity> questions) {
    return GestureDetector(
      onTap: () => _openPractice(context, questions),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 17.w, color: AppCustomColor.kpPeekHint),
          7.horizontalSpace,
          AppText(
            context.l10n.lesson.peekPracticeHint,
            style: AppStyle.text13.copyWith(
              fontWeight: FontWeight.w600,
              color: AppCustomColor.kpPeekHint,
            ),
          ),
        ],
      ),
    );
  }

  /// Full-width Continue (design: 54 tall, pill radius) — hands the reader to
  /// the completion screen the deck used to jump to on its own.
  Widget _continueButton(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppCustomColor.brandPrimary,
        borderRadius: BorderRadius.circular(999.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(999.r),
          onTap: () {
            AppHaptic.select();
            context.read<LessonCubit>().openKeypointComplete();
          },
          child: Container(
            height: 54.h,
            alignment: Alignment.center,
            child: AppText(
              context.l10n.common.kContinue,
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w700,
                color: AppCustomColor.textWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
