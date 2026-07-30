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
}
