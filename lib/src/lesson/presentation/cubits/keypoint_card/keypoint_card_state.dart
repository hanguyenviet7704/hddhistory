part of '../../../lesson.dart';

enum KeypointCardKind { theory, quiz, done }

/// One card in the unified keypoint swipe screen — either a theory content
/// block (one [DocumentEntity], the same granularity [TheoryCubit] already
/// pages through via `currentDocumentIndex`), one exercise [QuestionEntity],
/// or the synthetic terminal card reached once every real card is done.
///
/// Plain (non-freezed) value type: no JSON/`copyWith` needed here, just
/// structural equality so [KeypointCardState]'s generated `==` correctly
/// treats two descriptor lists built from the same content as equal (freezed
/// compares `List` fields element-by-element using each element's own `==`).
@immutable
class KeypointCardDescriptor {
  const KeypointCardDescriptor.theory({
    required this.learningItemId,
    required this.documentIndex,
  }) : kind = KeypointCardKind.theory,
       questionIndex = -1;

  const KeypointCardDescriptor.quiz({
    required this.learningItemId,
    required this.questionIndex,
  }) : kind = KeypointCardKind.quiz,
       documentIndex = -1;

  const KeypointCardDescriptor.done()
    : kind = KeypointCardKind.done,
      learningItemId = '',
      documentIndex = -1,
      questionIndex = -1;

  final KeypointCardKind kind;
  final String learningItemId;
  final int documentIndex;
  final int questionIndex;

  bool get isTheory => kind == KeypointCardKind.theory;
  bool get isQuiz => kind == KeypointCardKind.quiz;
  bool get isDone => kind == KeypointCardKind.done;

  @override
  bool operator ==(Object other) {
    return other is KeypointCardDescriptor &&
        other.kind == kind &&
        other.learningItemId == learningItemId &&
        other.documentIndex == documentIndex &&
        other.questionIndex == questionIndex;
  }

  @override
  int get hashCode => Object.hash(kind, learningItemId, documentIndex, questionIndex);
}

enum KeypointCardStatus { initial, ready }

@freezed
abstract class KeypointCardState with _$KeypointCardState {
  const factory KeypointCardState({
    @Default(KeypointCardStatus.initial) KeypointCardStatus status,
    @Default([]) List<KeypointCardDescriptor> cards,

    /// Freely browsable backward — which card the [PageView] currently shows.
    @Default(0) int viewedCardIndex,

    /// Progress-gated forward bound — the highest card index reachable right
    /// now. Bounded entirely by [LessonState]'s own existing progress (see
    /// `KeypointCardCubit`): it only ever advances once `TheoryCubit`/
    /// `ExerciseCubit`'s existing gate (`TheoryState.canContinue`, a checked
    /// question's stored result) allows the underlying content to advance.
    @Default(0) int furthestCardIndex,

    /// Highest card index the NARRATION reached while the app was off screen,
    /// which can sit past [furthestCardIndex]: the voice reads on through a gate
    /// the deck holds at, and coming back has to be able to show that page.
    ///
    /// Reachability only — this is NOT progress. No card counted here advanced
    /// `TheoryCubit`/`LessonCubit`, nothing was answered on the reader's behalf,
    /// and every card past [furthestCardIndex] renders read-only.
    @Default(0) int narrationRevealIndex,

    /// True for a short window right after a card change seeks playback —
    /// keeps a stale in-flight `just_audio` position tick from being read as
    /// "narration already finished this card" and bouncing to the next one
    /// (see `KeypointCardCubit.seekSuppressWindow`).
    @Default(false) bool isSeeking,

    /// Whether the live card is a quiz that already has a stored result.
    ///
    /// Mirrored into state deliberately: the card LIST doesn't change when a
    /// question is graded (same descriptors, same indices), so without this the
    /// rebuilt state compared equal, `emit` dropped it, and the shell never
    /// learned the forward swipe had been unlocked.
    @Default(false) bool isLiveCardAnswered,
  }) = _KeypointCardState;

  factory KeypointCardState.initial() => const KeypointCardState();
}

extension KeypointCardStateX on KeypointCardState {
  KeypointCardDescriptor get viewedCard => cards.elementAtOrDefault(viewedCardIndex, defaultValue: const KeypointCardDescriptor.done());

  bool get isViewingLiveCard => viewedCardIndex == furthestCardIndex;

  /// Furthest card the reader can reach right now: the lesson's live edge, or
  /// further when narration read ahead while the app was away.
  ///
  /// Only reachability reads this — the `PageView`'s item count and the pip
  /// bar's own reach. Everything asking "where is the lesson?" keeps reading
  /// [furthestCardIndex].
  int get revealBound => math.max(furthestCardIndex, narrationRevealIndex);
}
