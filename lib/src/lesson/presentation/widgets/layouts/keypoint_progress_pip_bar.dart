part of '../../../lesson.dart';

/// Segmented progress bar across the top of the unified keypoint swipe
/// screen — one pip per real card (theory document / quiz question; the
/// terminal done card isn't given its own pip). Tapping a pip already reached
/// jumps the `PageView` straight to it (same seek-on-navigate behavior as a
/// manual swipe — see `KeypointCardCubit.viewCard`).
class KeypointProgressPipBar extends StatelessWidget {
  const KeypointProgressPipBar({super.key});

  @override
  Widget build(BuildContext context) {
    // No horizontal padding of its own: this sits inside the header Row
    // (design), which already owns the screen edge inset.
    return BlocBuilder<KeypointCardCubit, KeypointCardState>(
        builder: (context, state) {
          // One pip per card in the WHOLE keypoint, shown from the start (per
          // design) — NOT one per already-revealed card, which would render a
          // single full-width bar that keeps subdividing as you advance.
          // `KeypointCardCubit`'s card list is built incrementally up to the
          // live card, so its length can't supply the total; LessonState's
          // existing `totalLessonInAllItems` already counts every theory
          // document + question across the keypoint. Falls back to the
          // revealed count if the total isn't resolvable.
          final revealedCardCount = state.cards.isEmpty ? 0 : state.cards.length - 1;
          final totalCards = context.select((LessonCubit cubit) => cubit.state.totalLessonInAllItems);
          final pipCount = totalCards > 0 ? totalCards : revealedCardCount;
          if (pipCount <= 0) return const SizedBox.shrink();

          final cubit = context.read<KeypointCardCubit>();
          // The live pip's fill is derived from the audio position, which
          // changes far more often than this cubit's state — watch the player
          // too so the bar creeps along with the voice instead of only
          // stepping when the narrated sentence changes.
          context.select((LessonAudioCubit audioCubit) => audioCubit.state.positionSeconds);

          return Semantics(
            label: context.l10n.lesson.cardProgressSemantics(
              current: state.viewedCardIndex + 1,
              total: pipCount,
            ),
            child: Row(
              children: List.generate(pipCount, (index) {
                final isReachable = index <= state.revealBound;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isReachable
                          ? () {
                              AppHaptic.select();
                              cubit.viewCard(index);
                            }
                          : null,
                      child: Container(
                        // Invisible hit-area padding keeps the tap target
                        // >=48dp tall even though the visual track is thin.
                        height: 24.h,
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99.r),
                          child: Container(
                            height: 5.h,
                            // Track/fill flip over a dark custom study
                            // background so the bar stays visible on photo
                            // themes (design's dark-chrome variant).
                            color: studyThemeIsDarkBg(context)
                                ? const Color(0xFF12141C).withValues(alpha: 0.45)
                                : AppCustomColor.backgroundWhite.withValues(alpha: 0.85),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: cubit.progressForCard(index),
                              child: Container(color: studyThemeOnBg(context, AppCustomColor.brandPrimary)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
      },
    );
  }
}
