import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

/// Reading a lesson written before the keypoint split.
///
/// This is not a courtesy to old data — it is what lets a new app run against an
/// API that has not been redeployed yet, which is the normal order for a mobile
/// release. Without it the reader refuses every existing lesson with "Something
/// went wrong" until the backend catches up.
void main() {
  group('body', () {
    test('folds a flat card list into one keypoint', () {
      final lesson = UserLessonModel.fromJson({
        'id': 'l1',
        'title': 'Bài cũ',
        'sections': [
          {
            'title': 'Card A',
            'blocks': [
              {'type': 'paragraph', 'text': 'A body'},
            ],
          },
          {
            'title': 'Card B',
            'blocks': [
              {'type': 'paragraph', 'text': 'B body'},
            ],
          },
        ],
      }).toEntity();

      expect(lesson.keypoints, hasLength(1));
      expect(lesson.keypoints.first.sections, hasLength(2));
      // Named after the lesson: the reader draws the keypoint title over every
      // card, and a blank strip is worse than a repeat of the lesson name.
      expect(lesson.keypoints.first.title, 'Bài cũ');
    });

    test('prefers keypoints when the server sends both', () {
      final lesson = UserLessonModel.fromJson({
        'id': 'l1',
        'keypoints': [
          {
            'title': 'Mới',
            'sections': [
              {
                'title': 'C',
                'blocks': [
                  {'type': 'paragraph', 'text': 'C body'},
                ],
              },
            ],
          },
        ],
        'sections': [
          {'title': 'Cũ', 'blocks': []},
        ],
      }).toEntity();

      expect(lesson.keypoints, hasLength(1));
      expect(lesson.keypoints.first.title, 'Mới');
    });

    test('stays empty when the body is absent, as on the list endpoint', () {
      final lesson = UserLessonModel.fromJson({'id': 'l1'}).toEntity();

      expect(lesson.keypoints, isEmpty);
      expect(lesson.hasBody, isFalse);
    });
  });

  group('narration', () {
    /// The old file IS the single keypoint's file, and a lesson-wide cue index
    /// IS that keypoint's card index — so nothing is lost in the conversion.
    test('re-addresses a lesson-wide file as keypoint 0', () {
      final lesson = UserLessonModel.fromJson({
        'id': 'l1',
        'sections': [
          {'title': 'A', 'blocks': []},
        ],
        'audio': {
          'url': 'https://cdn/old.mp3',
          'durationMs': 3000,
          'cues': [
            {'sectionIndex': 0, 'startMs': 0, 'durMs': 1000},
            {'sectionIndex': 1, 'startMs': 1000, 'durMs': 2000},
          ],
        },
      }).toEntity();

      final audio = lesson.audio!.forKeypoint(0)!;

      expect(audio.url, 'https://cdn/old.mp3');
      expect(audio.durationMs, 3000);
      expect(audio.cues.map((cue) => cue.cardIndex), [0, 1]);
      expect(audio.cues[1].startMs, 1000);
      expect(lesson.audio!.isPlayable, isTrue);
    });

    /// `cardIndex` and `sectionIndex` both default to zero if given defaults, so
    /// an old cue for card 3 would silently read as card 0 — the exact bug the
    /// nullable fields exist to prevent.
    test('does not collapse a legacy cue index to zero', () {
      final lesson = UserLessonModel.fromJson({
        'id': 'l1',
        'audio': {
          'url': 'https://cdn/old.mp3',
          'cues': [
            {'sectionIndex': 3, 'startMs': 500, 'durMs': 10},
          ],
        },
      }).toEntity();

      expect(lesson.audio!.forKeypoint(0)!.cues.first.cardIndex, 3);
    });

    test('reads the current shape unchanged', () {
      final lesson = UserLessonModel.fromJson({
        'id': 'l1',
        'audio': {
          'keypoints': [
            {
              'keypointIndex': 1,
              'url': 'https://cdn/kp1.mp3',
              'durationMs': 800,
              'cues': [
                {'cardIndex': 0, 'startMs': 0, 'durMs': 800},
              ],
            },
          ],
        },
      }).toEntity();

      expect(lesson.audio!.forKeypoint(1)!.url, 'https://cdn/kp1.mp3');
      expect(lesson.audio!.forKeypoint(0), isNull);
    });

    test('treats a lesson with no narration as ordinary, not broken', () {
      final lesson = UserLessonModel.fromJson({
        'id': 'l1',
        'audio': {'url': '', 'cues': []},
      }).toEntity();

      expect(lesson.audio!.isPlayable, isFalse);
      expect(lesson.audio!.forKeypoint(0), isNull);
    });
  });
}
