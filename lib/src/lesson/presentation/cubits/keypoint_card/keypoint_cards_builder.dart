part of '../../../lesson.dart';

/// Builds the card list for one keypoint from its learning items.
///
/// Pure on purpose — no cubit, no DI, no [LessonState]. This is the piece with
/// the fiddly index arithmetic (clip numbering that skips undubbed items, a live
/// edge that stops the list short), and it used to sit inside
/// [KeypointCardCubit], where testing it meant standing up `LessonCubit`,
/// `TheoryCubit` and `LessonAudioCubit` first. Callable with plain values, that
/// arithmetic is testable on its own.
///
/// Resolving where the reader is inside the current item stays the cubit's job
/// ([KeypointCardCubit._liveIndexForCurrentItem]) — it reads `TheoryCubit` /
/// `ExerciseCubit` — and arrives here as [liveIndexInCurrentItem].
class KeypointCardsBuilder {
  const KeypointCardsBuilder();

  BuiltKeypointCards build({
    required List<LearningItemEntity> items,
    required int currentLearningItemIndex,
    required int liveIndexInCurrentItem,
  }) {
    final cards = <KeypointCardDescriptor>[];
    final cardToClip = <int, int>{};
    var liveCardIndex = -1;

    if (items.isNotEmpty) {
      final lastItemIndex = math.min(currentLearningItemIndex, items.length - 1);
      // Clip numbering counts theory documents across the WHOLE keypoint, in the
      // order the backend dubbed them — so it keeps advancing past the revealed
      // edge and must not be derived from the (growing) card list.
      var clipPosition = 0;
      for (var itemIndex = 0; itemIndex <= lastItemIndex; itemIndex++) {
        final item = items[itemIndex];
        final isCurrentItem = itemIndex == currentLearningItemIndex;

        if (item.type == LearningItemType.theory || item.type == LearningItemType.video) {
          final documents = item.documents;
          if (documents.isEmpty) continue;
          // Video items are NOT dubbed — they carry their own audio, and the
          // backend leaves them out of its clip list (see
          // `VoiceoverService.buildSegments`). Counting their documents here
          // shifted every clip index after the first video, so those cards played
          // a neighbour's clip (or ran past the end and played nothing).
          final isDubbed = item.type == LearningItemType.theory;
          final activeDocIndex = isCurrentItem ? math.min(liveIndexInCurrentItem, documents.length - 1) : documents.length - 1;
          for (var docIndex = 0; docIndex <= activeDocIndex; docIndex++) {
            cards.add(KeypointCardDescriptor.theory(learningItemId: item.id, documentIndex: docIndex));
            if (isDubbed) cardToClip[cards.length - 1] = clipPosition + docIndex;
            if (isCurrentItem && docIndex == activeDocIndex) liveCardIndex = cards.length - 1;
          }
          if (isDubbed) clipPosition += documents.length;
        } else if (item.type == LearningItemType.exercise || item.type == LearningItemType.roleplay) {
          final questions = item.questions;
          if (questions.isEmpty) continue;
          // An exercise card's clip reads its QUESTION (the backend dubs the
          // question alone, never the options). Roleplay items are not dubbed —
          // they have their own recorded lines. Neither is the synthetic
          // sub-question round `LessonCubit.reviewDone` appends: its questions
          // come from `subQuestions`, which the backend never dubs, so counting
          // them would shift nothing but claim clips that don't exist.
          final isDubbed = item.type == LearningItemType.exercise && !item.isPlayingSubQuestions;
          final activeQuestionIndex = isCurrentItem ? math.min(liveIndexInCurrentItem, questions.length - 1) : questions.length - 1;
          for (var questionIndex = 0; questionIndex <= activeQuestionIndex; questionIndex++) {
            cards.add(KeypointCardDescriptor.quiz(learningItemId: item.id, questionIndex: questionIndex));
            if (isDubbed) cardToClip[cards.length - 1] = clipPosition + questionIndex;
            if (isCurrentItem && questionIndex == activeQuestionIndex) liveCardIndex = cards.length - 1;
          }
          if (isDubbed) clipPosition += questions.length;
        }
      }
    }

    if (liveCardIndex < 0) liveCardIndex = cards.isEmpty ? 0 : cards.length - 1;
    cards.add(const KeypointCardDescriptor.done());

    return BuiltKeypointCards(
      cards: cards,
      liveCardIndex: liveCardIndex,
      cardToClip: cardToClip,
    );
  }
}

class BuiltKeypointCards {
  const BuiltKeypointCards({
    required this.cards,
    required this.liveCardIndex,
    required this.cardToClip,
  });

  /// Includes the trailing synthetic done card.
  final List<KeypointCardDescriptor> cards;

  /// Index of the current active real card (== `doneCardIndex - 1`, or the
  /// done card's own index when there is no real content at all).
  final int liveCardIndex;

  /// Flat card index → narration-clip index (theory cards only).
  final Map<int, int> cardToClip;

  int get doneCardIndex => cards.length - 1;
}
