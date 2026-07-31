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
    // No horizontal padding of its own: [LessonShellHeader] gives this its own
    // row under the controls and owns the (wider) inset the design asks for.
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
                // The design gives the card being read a pip 5x the width of the
                // others and 2pt taller (`flex: i === cur ? 5 : 1`,
                // `h: i === cur ? '7px' : '5px'`), animated — so the bar reads as
                // "you are here" rather than as an even row of ticks.
                final isCurrent = index == state.viewedCardIndex;
                return Expanded(
                  flex: isCurrent ? 5 : 1,
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          height: (isCurrent ? 7 : 5).h,
                          decoration: BoxDecoration(
                            // Theme-independent, per the design's own note that
                            // the header chrome is the same on every theme —
                            // white track, indigo fill. See [KeypointHeaderChrome].
                            color: KeypointHeaderChrome.pipTrack,
                            borderRadius: BorderRadius.circular(99.r),
                          ),
                          clipBehavior: Clip.antiAlias,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: cubit.progressForCard(index),
                            // Container, NOT DecoratedBox: with no child a
                            // DecoratedBox takes the SMALLEST size its
                            // constraints allow, so the fill collapsed to zero
                            // height and the bar showed only its track.
                            child: Container(
                              decoration: BoxDecoration(
                                color: KeypointHeaderChrome.pipFill,
                                borderRadius: BorderRadius.circular(99.r),
                              ),
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
