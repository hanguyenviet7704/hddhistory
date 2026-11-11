import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../../support/test_di.dart';

/// Rules of the background listening chain — how far a hands-free listen carries
/// down the roadmap. See `plans/260810-listen-across-keypoints/README.md`.
void main() {
  // `resolvedMergedAudio` resolves the dub by active locale, which reads
  // LocaleCubit out of the injector.
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
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

  LessonEntity lessonOf(
    List<KeypointEntity> keypoints, {
    String id = 'lesson-1',
    LessonType type = LessonType.lesson,
  }) => LessonEntity(id: id, type: type, keypoints: keypoints);

  /// The roadmap holds ONE ENTRY PER KEYPOINT (`lessonsList` expands a lesson
  /// per keypoint) — the tiles the reader sees, in the order they hear them.
  List<LessonEntity> stopsOf(List<LessonEntity> lessons) => lessons.expand((lesson) => lesson.lessonsPerKeypoint).toList();

  ChainStep stepFrom(
    String currentKeypointId, {
    required List<LessonEntity> roadmap,
    LessonEntity? openLesson,
    Set<String> gated = const {},
    Set<String> lockedKeypoints = const {},
  }) => resolveChainStep(
    roadmapStops: stopsOf(roadmap),
    openLesson: openLesson ?? roadmap.first,
    currentKeypointId: currentKeypointId,
    isPaywallGated: (candidate) => gated.contains(candidate.id),
    isLessonLocked: (stop) => lockedKeypoints.contains(stop.roadmapKey),
  );

  ChainStopReason? reasonOf(ChainStep step) => step is ChainStepEnd ? step.reason : null;

  group('resolveChainStep — within the open lesson', () {
    test('hands back the next keypoint in roadmap order', () {
      final lesson = lessonOf([keypoint('kp-1'), keypoint('kp-2'), keypoint('kp-3')]);
      final roadmap = [lesson];

      expect((stepFrom('kp-1', roadmap: roadmap) as ChainStepInLesson).keypoint.id, 'kp-2');
      expect((stepFrom('kp-2', roadmap: roadmap) as ChainStepInLesson).keypoint.id, 'kp-3');
    });

    test('stops at a keypoint with no usable merged audio rather than skipping it', () {
      // Skipping would leave a keypoint the reader believes they heard, and it
      // would never be marked complete.
      final lesson = lessonOf([keypoint('kp-1'), keypoint('kp-2', dubbed: false), keypoint('kp-3')]);

      expect(reasonOf(stepFrom('kp-1', roadmap: [lesson])), ChainStopReason.noMergedDub);
    });

    test('stops at a paywalled keypoint', () {
      final lesson = lessonOf([keypoint('kp-1'), keypoint('kp-2')]);

      expect(reasonOf(stepFrom('kp-1', roadmap: [lesson], gated: {'kp-2'})), ChainStopReason.paywall);
    });

    test('carries on into a keypoint that is already completed', () {
      // Someone re-listening to a finished lesson keeps hearing it through.
      final lesson = lessonOf([keypoint('kp-1', done: true), keypoint('kp-2', done: true)]);

      expect((stepFrom('kp-1', roadmap: [lesson]) as ChainStepInLesson).keypoint.id, 'kp-2');
    });

    test('ends the chain when the current keypoint is unset', () {
      expect(reasonOf(stepFrom('', roadmap: [lessonOf([keypoint('kp-1')])])), ChainStopReason.unknownPosition);
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

      expect(reasonOf(stepFrom('kp-1', roadmap: [lessonOf([keypoint('kp-1'), silent])])), ChainStopReason.noMergedDub);
    });
  });

  group('resolveChainStep — crossing a lesson', () {
    final lessonOne = lessonOf([keypoint('kp-1'), keypoint('kp-2')]);
    final lessonTwo = lessonOf([keypoint('kp-3'), keypoint('kp-4')], id: 'lesson-2');

    test('hands back the next lesson by id — its dub is not in the roadmap', () {
      // The roadmap stub carries only the legacy per-language url, so the
      // candidate cannot be resolved to a queueable keypoint here.
      final step = stepFrom('kp-2', roadmap: [lessonOne, lessonTwo]) as ChainStepNextLesson;

      expect(step.lessonId, 'lesson-2');
      expect(step.keypointId, 'kp-3');
    });

    test('ends the chain at the last keypoint of the last lesson', () {
      expect(
        reasonOf(stepFrom('kp-4', roadmap: [lessonOne, lessonTwo], openLesson: lessonTwo)),
        ChainStopReason.endOfRoadmap,
      );
    });

    test('stops at a lesson behind lesson lock', () {
      expect(
        reasonOf(stepFrom('kp-2', roadmap: [lessonOne, lessonTwo], lockedKeypoints: {'kp-3'})),
        ChainStopReason.lessonLocked,
      );
    });

    test('stops at the first keypoint of the next lesson being paywalled', () {
      expect(
        reasonOf(stepFrom('kp-2', roadmap: [lessonOne, lessonTwo], gated: {'kp-3'})),
        ChainStopReason.paywall,
      );
    });

    test('stops at a roadmap stop that is not read out loud', () {
      // Roleplay / video / output practice. They gate the roadmap, so reading
      // past one would narrate content the app itself has locked.
      final roleplay = lessonOf([keypoint('rp-1')], id: 'roleplay-1', type: LessonType.roleplay);

      expect(
        reasonOf(stepFrom('kp-2', roadmap: [lessonOne, roleplay, lessonTwo])),
        ChainStopReason.nonReadableStop,
      );
    });

    test('walks the open lesson when the keypoint is on no roadmap (a generated lesson)', () {
      // An imported lesson exists on no roadmap; it still chains through its own
      // keypoints, and has nothing to cross to.
      final generated = lessonOf([keypoint('gen-1'), keypoint('gen-2')], id: 'user-lesson-1');

      expect(
        (stepFrom('gen-1', roadmap: [lessonOne], openLesson: generated) as ChainStepInLesson).keypoint.id,
        'gen-2',
      );
      expect(
        reasonOf(stepFrom('gen-2', roadmap: [lessonOne], openLesson: generated)),
        ChainStopReason.endOfRoadmap,
      );
    });
  });
}
