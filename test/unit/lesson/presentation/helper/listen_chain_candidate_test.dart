import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

/// Rules of the background listening chain — how far a hands-free listen carries
/// across keypoints. See `plans/260810-listen-across-keypoints/README.md`.
void main() {
  // `resolvedMergedAudio` resolves the dub by active locale, which reads
  // LocaleCubit out of the injector.
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  KeypointEntity keypoint(String id, {bool dubbed = true, bool done = false}) => KeypointEntity(
    id: id,
    title: BaseMultiLanguage(en: id),
    progess: done ? ProcessEnum.done : ProcessEnum.notStarted,
    audio: dubbed
        ? KeypointAudioEntity(
            merged: {
              'en': MergedKeypointAudioEntity(
                url: 'https://cdn.test/$id.mp3',
                durationMs: 60000,
                cues: const [MergedAudioCueEntity(learningItemId: 'item-1', documentIndex: 0, startMs: 0, durMs: 60000)],
              ),
            },
          )
        : null,
  );

  LessonEntity lessonOf(List<KeypointEntity> keypoints) => LessonEntity(id: 'lesson-1', keypoints: keypoints);

  KeypointEntity? candidateIn(
    LessonEntity lesson,
    String currentKeypointId, {
    Set<String> gated = const {},
  }) => resolveChainCandidate(
    lesson: lesson,
    currentKeypointId: currentKeypointId,
    isPaywallGated: (candidate) => gated.contains(candidate.id),
  );

  group('resolveChainCandidate', () {
    test('hands back the next keypoint in lesson order', () {
      final lesson = lessonOf([keypoint('kp-1'), keypoint('kp-2'), keypoint('kp-3')]);

      expect(candidateIn(lesson, 'kp-1')?.id, 'kp-2');
      expect(candidateIn(lesson, 'kp-2')?.id, 'kp-3');
    });

    test('ends the chain at the last keypoint of the lesson', () {
      final lesson = lessonOf([keypoint('kp-1'), keypoint('kp-2')]);

      expect(candidateIn(lesson, 'kp-2'), isNull);
    });

    test('stops at a keypoint with no usable merged audio rather than skipping it', () {
      // Skipping would leave a keypoint the reader believes they heard, and it
      // would never be marked complete.
      final lesson = lessonOf([keypoint('kp-1'), keypoint('kp-2', dubbed: false), keypoint('kp-3')]);

      expect(candidateIn(lesson, 'kp-1'), isNull);
    });

    test('stops at a paywalled keypoint', () {
      final lesson = lessonOf([keypoint('kp-1'), keypoint('kp-2')]);

      expect(candidateIn(lesson, 'kp-1', gated: {'kp-2'}), isNull);
    });

    test('carries on into a keypoint that is already completed', () {
      // Someone re-listening to a finished lesson keeps hearing it through.
      final lesson = lessonOf([keypoint('kp-1', done: true), keypoint('kp-2', done: true)]);

      expect(candidateIn(lesson, 'kp-1')?.id, 'kp-2');
    });

    test('ends the chain when the current keypoint is unknown or unset', () {
      final lesson = lessonOf([keypoint('kp-1'), keypoint('kp-2')]);

      expect(candidateIn(lesson, ''), isNull);
      expect(candidateIn(lesson, 'kp-not-in-lesson'), isNull);
    });

    test('ends the chain when a merged file has no audible cue', () {
      final silent = KeypointEntity(
        id: 'kp-2',
        audio: KeypointAudioEntity(
          merged: {
            'en': MergedKeypointAudioEntity(
              url: 'https://cdn.test/kp-2.mp3',
              cues: const [MergedAudioCueEntity(learningItemId: 'item-1', documentIndex: 0, startMs: 0, durMs: 0)],
            ),
          },
        ),
      );

      expect(candidateIn(lessonOf([keypoint('kp-1'), silent]), 'kp-1'), isNull);
    });
  });
}
