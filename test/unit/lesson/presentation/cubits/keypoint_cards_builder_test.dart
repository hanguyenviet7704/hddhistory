import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

// `documents` is List<DocumentEntity>; `questions` is an extension getter over
// `mainQuestions`, so an exercise fixture passes mainQuestions. Both entities
// default every field, so an id is all a fixture needs.
LearningItemEntity _theory(String id, int docs) => LearningItemEntity(
  id: id,
  type: LearningItemType.theory,
  documents: List.generate(docs, (i) => DocumentEntity(id: i)),
);

LearningItemEntity _exercise(String id, int questions) => LearningItemEntity(
  id: id,
  type: LearningItemType.exercise,
  mainQuestions: List.generate(questions, (i) => QuestionEntity(id: i)),
);

LearningItemEntity _video(String id, int docs) => LearningItemEntity(
  id: id,
  type: LearningItemType.video,
  documents: List.generate(docs, (i) => DocumentEntity(id: i)),
);

void main() {
  const builder = KeypointCardsBuilder();

  test('builds only as far as the live position, plus the done card', () {
    final built = builder.build(
      items: [_theory('t1', 3), _exercise('e1', 2)],
      currentLearningItemIndex: 0,
      liveIndexInCurrentItem: 1,
    );

    // Cards 0..1 of the 3 theory docs, then the synthetic done card.
    expect(built.cards.length, 3);
    expect(built.cards[0].isTheory, isTrue);
    expect(built.cards[1].documentIndex, 1);
    expect(built.cards.last.isDone, isTrue);
    expect(built.liveCardIndex, 1);
    expect(built.doneCardIndex, 2);
  });

  test('clip numbering counts every document of a dubbed item, revealed or not', () {
    final built = builder.build(
      items: [_theory('t1', 3), _theory('t2', 2)],
      currentLearningItemIndex: 1,
      liveIndexInCurrentItem: 0,
    );

    // t1 contributes clips 0..2 even though t2 is only revealed to its first doc.
    expect(built.cardToClip[0], 0);
    expect(built.cardToClip[2], 2);
    expect(built.cardToClip[3], 3);
  });

  test('video items contribute cards but claim no clips', () {
    final built = builder.build(
      items: [_video('v1', 2), _theory('t1', 1)],
      currentLearningItemIndex: 1,
      liveIndexInCurrentItem: 0,
    );

    expect(built.cardToClip.containsKey(0), isFalse);
    expect(built.cardToClip.containsKey(1), isFalse);
    expect(built.cardToClip[2], 0);
  });

  test('exercise items contribute clips but no cards', () {
    // The exercise flow left the keypoint screen (PO, 2026-07-30): e1's two
    // dubbed question clips still occupy slots 1..2 in the backend numbering,
    // but no quiz card exists and its clips are not narratable.
    final built = builder.build(
      items: [_theory('t1', 1), _exercise('e1', 2), _theory('t2', 1)],
      currentLearningItemIndex: 2,
      liveIndexInCurrentItem: 0,
    );

    expect(built.cards.where((c) => c.isQuiz), isEmpty);
    expect(built.cards.length, 3); // t1 d0, t2 d0, done
    expect(built.cardToClip[0], 0);
    expect(built.cardToClip[1], 3); // t2 d0 sits past e1's two question clips
    expect(built.narratableClips, {0, 3});
  });

  test('extends past the live edge until the narrated clip has a card', () {
    final built = builder.build(
      items: [_theory('t1', 2), _exercise('e1', 2), _theory('t2', 2)],
      currentLearningItemIndex: 2,
      liveIndexInCurrentItem: 0,
      // Live edge is t2's first document (card 2, clip 4 — e1's question clips
      // hold slots 2..3). The voice is on clip 5, one card past the edge.
      revealToClipIndex: 5,
    );

    expect(built.liveCardIndex, 2);
    expect(built.revealCardIndex, 3);
    expect(built.cards[3].isTheory, isTrue);
    expect(built.cards[3].learningItemId, 't2');
    expect(built.cardToClip[3], 5);
    // The done card still comes last.
    expect(built.cards.last.isDone, isTrue);
  });

  test('stops as soon as the narrated clip is covered, never further', () {
    final built = builder.build(
      items: [_theory('t1', 1), _theory('t2', 4)],
      currentLearningItemIndex: 0,
      liveIndexInCurrentItem: 0,
      revealToClipIndex: 2,
    );

    // t1 doc 0 (clip 0) is live; t2 docs 0..1 are clips 1..2. Clip 2 is card 2,
    // so t2's remaining two documents must NOT be built.
    expect(built.revealCardIndex, 2);
    expect(built.cards.length, 4); // 3 real cards + done
  });

  test('reveal bound never shortens the list and is ignored when unreachable', () {
    final built = builder.build(
      items: [_theory('t1', 2)],
      currentLearningItemIndex: 0,
      liveIndexInCurrentItem: 1,
      revealToClipIndex: 99,
    );

    expect(built.cards.length, 3); // 2 docs + done
    expect(built.revealCardIndex, built.liveCardIndex);
  });

  test('no reveal bound builds exactly what it built before', () {
    final withNone = builder.build(
      items: [_theory('t1', 3), _exercise('e1', 2)],
      currentLearningItemIndex: 0,
      liveIndexInCurrentItem: 1,
    );

    expect(withNone.cards.length, 3);
    expect(withNone.revealCardIndex, withNone.liveCardIndex);
  });
}
