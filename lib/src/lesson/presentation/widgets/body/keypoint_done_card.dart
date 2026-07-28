part of '../../../lesson.dart';

/// Terminal card of the unified keypoint swipe screen.
///
/// Under normal progress, [LessonCubit.completeCurrentKeypoint] has ALREADY
/// fired by the time this card is shown — finishing the last real card calls
/// `TheoryCubit.nextDocument()` / `ExerciseCubit.nextQuestion()` exactly as
/// before this feature, which cascades into `LessonCubit.nextLearningItem()`
/// → `completeCurrentKeypoint()` → `KeypointCompleteRoute`. `KeypointCardCubit`
/// reveals this card the instant that happens (see its `completionOrigin`
/// handling), so it's typically visible only for the frame(s) before that
/// route's transition covers it — matching decision #3: completion is never
/// bypassed by audio, and always goes through the same gate Read mode always
/// used.
///
/// The explicit call below is a fallback for the one path where nothing else
/// would have triggered completion: a keypoint with no content at all.
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: const BoxDecoration(color: AppCustomColor.brandPrimary50, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(Icons.check_rounded, size: 40.w, color: AppCustomColor.brandPrimary),
            ),
            20.verticalSpace,
            AppText(
              context.l10n.lesson.doneCardTitle,
              textAlign: TextAlign.center,
              style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
            ),
            8.verticalSpace,
            AppText(
              context.l10n.lesson.doneCardSubtitle,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
