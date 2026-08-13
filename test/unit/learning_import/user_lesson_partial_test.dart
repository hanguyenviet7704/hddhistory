// Pins the readiness rules a PARTIALLY-generated lesson lives by
// (plans/260813-progressive-import on the API side): which roadmap nodes may
// open, what the roadmap keeps polling for, and how the planned outline and the
// written body reconcile into one node list.
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

LessonKeypointEntity _keypoint(String title) => LessonKeypointEntity(
  title: title,
  sections: const [LessonSectionEntity(title: 'Card')],
);

UserLessonKeypointAudioEntity _audio(int index) => UserLessonKeypointAudioEntity(
  keypointIndex: index,
  url: 'https://cdn/kp-$index.mp3',
  durationMs: 1000,
  cues: const [UserLessonAudioCueEntity(durMs: 1000)],
);

void main() {
  group('keypointReady', () {
    test('a written keypoint with its narration is ready', () {
      final lesson = UserLessonEntity(
        keypoints: [_keypoint('A'), _keypoint('B')],
        audioStatus: UserLessonAudioStatusEntity.ready,
        audio: UserLessonAudioEntity(keypoints: [_audio(0)]),
      );

      expect(lesson.keypointReady(0), isTrue);
      // Written, but the background phase still owes it narration.
      expect(lesson.keypointReady(1), isFalse);
      // Not written at all.
      expect(lesson.keypointReady(2), isFalse);
    });

    test('the audio gate lifts when narration is never coming', () {
      for (final status in [
        UserLessonAudioStatusEntity.failed,
        UserLessonAudioStatusEntity.none,
      ]) {
        final lesson = UserLessonEntity(
          keypoints: [_keypoint('A')],
          audioStatus: status,
        );

        expect(
          lesson.keypointReady(0),
          isTrue,
          reason:
              '$status means no narration will ever arrive — gating on it '
              'would lock the lesson shut forever',
        );
      }
    });

    test('processing holds every undubbed keypoint back', () {
      final lesson = UserLessonEntity(
        keypoints: [_keypoint('A')],
        audioStatus: UserLessonAudioStatusEntity.processing,
      );

      expect(lesson.keypointReady(0), isFalse);
    });
  });

  group('planned outline', () {
    final lesson = UserLessonEntity(
      keypoints: [_keypoint('Written title')],
      plannedKeypointTitles: const ['Planned 1', 'Planned 2', 'Planned 3'],
      contentStatus: UserLessonContentStatusEntity.partial,
    );

    test('the roadmap draws the PLAN, not just the body', () {
      expect(lesson.plannedKeypointCount, 3);
    });

    test('a written keypoint shows its own title, an unwritten one its plan', () {
      // The body's title wins where it exists — phase 2 pins keypoint titles to
      // the plan server-side, but the body is the fact and the plan the promise.
      expect(lesson.plannedTitleAt(0), 'Written title');
      expect(lesson.plannedTitleAt(1), 'Planned 2');
      expect(lesson.plannedTitleAt(9), '');
    });

    test('the body wins when it is somehow longer than the plan', () {
      final overgrown = UserLessonEntity(
        keypoints: [_keypoint('A'), _keypoint('B')],
        plannedKeypointTitles: const ['A'],
      );

      expect(overgrown.plannedKeypointCount, 2);
    });
  });

  group('isStillMaterializing', () {
    test('true while the body is partial', () {
      final lesson = UserLessonEntity(
        keypoints: [_keypoint('A')],
        contentStatus: UserLessonContentStatusEntity.partial,
        audioStatus: UserLessonAudioStatusEntity.ready,
        audio: UserLessonAudioEntity(keypoints: [_audio(0)]),
      );

      expect(lesson.isStillMaterializing, isTrue);
    });

    test('true when complete but a keypoint still awaits narration', () {
      final lesson = UserLessonEntity(
        keypoints: [_keypoint('A'), _keypoint('B')],
        contentStatus: UserLessonContentStatusEntity.complete,
        audioStatus: UserLessonAudioStatusEntity.ready,
        audio: UserLessonAudioEntity(keypoints: [_audio(0)]),
      );

      expect(lesson.isStillMaterializing, isTrue);
    });

    test('false once everything is written and dubbed — the poll stops', () {
      final lesson = UserLessonEntity(
        keypoints: [_keypoint('A'), _keypoint('B')],
        contentStatus: UserLessonContentStatusEntity.complete,
        audioStatus: UserLessonAudioStatusEntity.ready,
        audio: UserLessonAudioEntity(keypoints: [_audio(0), _audio(1)]),
      );

      expect(lesson.isStillMaterializing, isFalse);
    });

    test('false for an old lesson that never had audio', () {
      final lesson = UserLessonEntity(
        keypoints: [_keypoint('A')],
        contentStatus: UserLessonContentStatusEntity.complete,
        audioStatus: UserLessonAudioStatusEntity.none,
      );

      expect(lesson.isStillMaterializing, isFalse);
    });
  });
}
