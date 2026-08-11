import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../support/test_di.dart';

/// The seam that lets a generated lesson be read by the CATALOGUE's reader.
///
/// Worth testing precisely because nothing else can catch it: the mapper's
/// output is consumed by widgets and cubits that a static check is happy to
/// build against, so a wrong document index or a cue pointing at the wrong
/// learning item shows up only as narration reading the wrong card on a device.
void main() {
  // `hasUsableAudio` resolves the active locale through `BaseMultiLanguage.text`,
  // which reaches into the DI graph. The reader does the same, so the test has
  // to as well — asserting on the raw field instead would pass even if the
  // gate stopped reading it.
  setUpAll(() async => setupLocaleCubitForTests(locale: AppLocale.vi));

  UserLessonEntity lessonOf({
    List<LessonKeypointEntity> keypoints = const [],
    UserLessonAudioEntity? audio,
    String locale = 'vi',
  }) {
    return UserLessonEntity(
      id: 'lesson1',
      title: 'Tiêu đề',
      outputLocale: locale,
      keypoints: keypoints,
      audio: audio,
    );
  }

  LessonKeypointEntity keypointOf(String title, List<String> cardTitles) {
    return LessonKeypointEntity(
      title: title,
      sections: [
        for (final cardTitle in cardTitles)
          LessonSectionEntity(
            title: cardTitle,
            blocks: [LessonBlockEntity(text: '$cardTitle body')],
          ),
      ],
    );
  }

  group('toLesson', () {
    test('gives one KeypointEntity per keypoint, in order', () {
      final lesson = UserLessonCourseMapper.toLesson(
        lessonOf(keypoints: [keypointOf('Một', ['a']), keypointOf('Hai', ['b'])]),
      );

      expect(lesson.keypoints, hasLength(2));
      expect(lesson.keypoints[0].index, 0);
      expect(lesson.keypoints[1].index, 1);
      expect(lesson.keypoints[1].title.vi, 'Hai');
    });

    /// An empty courseId is what keeps a generated lesson out of the Live
    /// Activity, the roadmap and the progress writes — every one of those bails
    /// out on it. Inventing an id here would start a "Đang học" card pointing at
    /// a course that does not exist.
    test('leaves courseId empty', () {
      final lesson = UserLessonCourseMapper.toLesson(
        lessonOf(keypoints: [keypointOf('Một', ['a'])]),
      );

      expect(lesson.courseId, isEmpty);
      expect(lesson.isImported, isTrue);
    });

    test('does not mistake a catalogue lesson for an imported one', () {
      expect(const LessonEntity(id: '507f1f77bcf86cd799439011').isImported, isFalse);
    });

    test('writes the title into the lesson own locale slot', () {
      final lesson = UserLessonCourseMapper.toLesson(
        lessonOf(keypoints: [keypointOf('Một', ['a'])], locale: 'ja'),
      );

      expect(lesson.title.ja, 'Tiêu đề');
      expect(lesson.title.en, isEmpty);
    });
  });

  group('learningItemsOf', () {
    test('turns one keypoint into ONE theory item whose documents are its cards', () {
      final lesson = lessonOf(keypoints: [keypointOf('Một', ['a', 'b', 'c'])]);

      final items = UserLessonCourseMapper.learningItemsOf(lesson, 0);

      expect(items, hasLength(1));
      expect(items.first.type, LearningItemType.theory);
      expect(items.first.documents, hasLength(3));
    });

    /// The reader draws one card per DOCUMENT, and the document's index is what
    /// narration cues address. Off-by-one here reads card two aloud over card one.
    test('numbers documents from zero in card order', () {
      final lesson = lessonOf(keypoints: [keypointOf('Một', ['a', 'b'])]);

      final documents = UserLessonCourseMapper.learningItemsOf(lesson, 0).first.documents;

      expect(documents[0].id, 0);
      expect(documents[1].id, 1);
      expect(documents[1].document.first.data.content.vi, 'b');
    });

    test('renders the card heading as a title block and the body as text', () {
      final lesson = lessonOf(keypoints: [keypointOf('Một', ['a'])]);

      final contents = UserLessonCourseMapper.learningItemsOf(lesson, 0).first.documents.first.document;

      expect(contents.first.type, ContentDocumentType.title);
      expect(contents.first.data.content.vi, 'a');
      expect(contents[1].type, ContentDocumentType.text);
      expect(contents[1].data.content.vi, 'a body');
    });

    test('marks a heading block as a title, not body text', () {
      final lesson = lessonOf(
        keypoints: [
          LessonKeypointEntity(
            title: 'Một',
            sections: [
              LessonSectionEntity(
                title: '',
                blocks: [
                  LessonBlockEntity(type: LessonBlockTypeEntity.heading, text: 'Đề mục'),
                ],
              ),
            ],
          ),
        ],
      );

      final contents = UserLessonCourseMapper.learningItemsOf(lesson, 0).first.documents.first.document;

      expect(contents, hasLength(1));
      expect(contents.first.type, ContentDocumentType.title);
    });

    test('returns nothing for an index no keypoint has', () {
      final lesson = lessonOf(keypoints: [keypointOf('Một', ['a'])]);

      expect(UserLessonCourseMapper.learningItemsOf(lesson, 5), isEmpty);
      expect(UserLessonCourseMapper.learningItemsOf(lesson, -1), isEmpty);
    });

    test('ties the item to its own keypoint id', () {
      final lesson = lessonOf(keypoints: [keypointOf('Một', ['a']), keypointOf('Hai', ['b'])]);

      final mapped = UserLessonCourseMapper.toLesson(lesson);
      final item = UserLessonCourseMapper.learningItemsOf(lesson, 1).first;

      expect(item.keypointId, mapped.keypoints[1].id);
    });
  });

  group('narration', () {
    UserLessonEntity dubbedLesson() => lessonOf(
      keypoints: [keypointOf('Một', ['a', 'b']), keypointOf('Hai', ['c'])],
      audio: const UserLessonAudioEntity(
        keypoints: [
          UserLessonKeypointAudioEntity(
            keypointIndex: 0,
            url: 'https://cdn/kp0.mp3',
            durationMs: 3000,
            cues: [
              UserLessonAudioCueEntity(cardIndex: 0, startMs: 0, durMs: 1000),
              UserLessonAudioCueEntity(cardIndex: 1, startMs: 1000, durMs: 2000),
            ],
          ),
        ],
      ),
    );

    /// `LessonPage._syncAudioKeypoint` gates narration on `hasUsableAudio`,
    /// which reads `audio.url` and nothing else. Filling only `merged` produced
    /// a keypoint the player could have read aloud and the page never asked.
    test('fills url as well as merged, or narration never starts', () {
      final mapped = UserLessonCourseMapper.toLesson(dubbedLesson());

      expect(mapped.keypoints[0].hasUsableAudio, isTrue);
    });

    test('points every cue at the keypoint own learning item', () {
      final lesson = dubbedLesson();
      final mapped = UserLessonCourseMapper.toLesson(lesson);
      final itemId = UserLessonCourseMapper.learningItemsOf(lesson, 0).first.id;

      final merged = mapped.keypoints[0].audio!.merged!['vi']!;

      expect(merged.cues.map((cue) => cue.learningItemId), everyElement(itemId));
      expect(merged.cues.map((cue) => cue.documentIndex), [0, 1]);
      expect(merged.cues[1].startMs, 1000);
    });

    test('leaves a keypoint that was never dubbed silent rather than broken', () {
      final mapped = UserLessonCourseMapper.toLesson(dubbedLesson());

      expect(mapped.keypoints[1].audio, isNull);
      expect(mapped.keypoints[1].hasUsableAudio, isFalse);
    });
  });

  group('id round-trip', () {
    test('reads the keypoint index and lesson id back out', () {
      final mapped = UserLessonCourseMapper.toLesson(
        lessonOf(keypoints: [keypointOf('Một', ['a']), keypointOf('Hai', ['b'])]),
      );

      final id = mapped.keypoints[1].id;

      expect(UserLessonCourseMapper.keypointIndexOf(id), 1);
      expect(UserLessonCourseMapper.lessonIdOf(id), 'lesson1');
    });

    /// The completion screen asks this of EVERY keypoint it finishes, catalogue
    /// ones included — a false positive would send a course reader to the
    /// imported-lesson shelf.
    test('rejects a catalogue id', () {
      expect(UserLessonCourseMapper.keypointIndexOf('507f1f77bcf86cd799439011'), -1);
      expect(UserLessonCourseMapper.lessonIdOf('507f1f77bcf86cd799439011'), isEmpty);
    });
  });
}
