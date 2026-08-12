import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

/// `CourseLessonCubit` owns which lesson the reader is inside. Two behaviours it
/// has to get right for the background listening chain, which moves that lesson
/// out from under an in-flight refresh — see `ListenChainController`.
class _FakeCourseLessonRepository implements ICourseLessonRepository {
  _FakeCourseLessonRepository(this.getCourseLessonHandler);

  TaskEither<AppException, LessonEntity> Function(String id) getCourseLessonHandler;

  @override
  TaskEither<AppException, BasePageBreak<LessonEntity>> getAllCourseLessons(PageBreakRequest request) =>
      TaskEither.right(const BasePageBreak<LessonEntity>());

  @override
  TaskEither<AppException, LessonEntity> getCourseLesson(String id) => getCourseLessonHandler(id);
}

class _FakeRemoteConfigService implements IRemoteConfigService {
  @override
  AppFunctionEntity get appFunction => const AppFunctionEntity();
  @override
  AppVersionConfigEntity get appVersionConfig => const AppVersionConfigEntity();
  // Off, so `checkAndFinishOptionalKeypoints` returns before reaching the
  // injector — this test is about which lesson wins, nothing else.
  @override
  CourseConfigEntity get courseConfig => const CourseConfigEntity(enableFinishOptionalKeypoints: false);
  @override
  OnboardingConfigEntity get onboardingConfig => const OnboardingConfigEntity();
  @override
  PaywallConfigEntity get paywallConfig => const PaywallConfigEntity();
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> shouldForceUpdate() async => false;
  @override
  Future<bool> optionalUpdateAvailable() async => false;
}

void main() {
  LessonEntity lessonOf(String id, {String keypointId = ''}) => LessonEntity(
    id: id,
    keypoints: keypointId.isEmpty ? const [] : [KeypointEntity(id: keypointId)],
  );

  group('loadLesson', () {
    test('applies the refresh of the lesson that is still open', () async {
      final cubit = CourseLessonCubit(
        GetCourseLessonUseCase(_FakeCourseLessonRepository((id) => TaskEither.right(lessonOf(id, keypointId: 'kp-1')))),
        _FakeRemoteConfigService(),
      );
      cubit.setSelectedLesson(lessonOf('lesson-1'));

      cubit.loadLesson('lesson-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedLesson.keypoints.single.id, 'kp-1');
      await cubit.close();
    });

    test('drops the refresh of a lesson the reader has already left', () async {
      // `ProgressCubit` fires a refresh of the OPEN lesson after every keypoint
      // write; the listening chain can cross into the next lesson while it is in
      // flight. Landing it would drag `selectedLesson` back, and
      // `resolvedCurrentKeypoint` would fall back to that lesson's first keypoint
      // — the deck reloads and re-reads a keypoint heard long ago.
      final cubit = CourseLessonCubit(
        GetCourseLessonUseCase(_FakeCourseLessonRepository((id) => TaskEither.right(lessonOf(id, keypointId: 'kp-1')))),
        _FakeRemoteConfigService(),
      );
      cubit.setSelectedLesson(lessonOf('lesson-1'));

      cubit.loadLesson('lesson-1');
      // The hop, before the response lands.
      cubit.enterLesson(lesson: lessonOf('lesson-2', keypointId: 'kp-9'), keypointId: 'kp-9');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedLesson.id, 'lesson-2');
      expect(cubit.state.currentKeypointId, 'kp-9');
      await cubit.close();
    });
  });

  group('enterLesson', () {
    test('swaps lesson and keypoint in a single emission', () async {
      final cubit = CourseLessonCubit(
        GetCourseLessonUseCase(_FakeCourseLessonRepository((id) => TaskEither.right(lessonOf(id)))),
        _FakeRemoteConfigService(),
      );
      cubit.setSelectedLesson(lessonOf('lesson-1', keypointId: 'kp-1'));
      cubit.setCurrentKeypointId('kp-1');

      final states = <CourseLessonState>[];
      final subscription = cubit.stream.listen(states.add);
      cubit.enterLesson(lesson: lessonOf('lesson-2', keypointId: 'kp-9'), keypointId: 'kp-9');
      await Future<void>.delayed(Duration.zero);

      // One emission, and never the in-between state where the new lesson is
      // selected while `currentKeypointId` still names the old lesson's keypoint
      // (there, `resolvedCurrentKeypoint` silently falls back to the new lesson's
      // first keypoint and `LessonPage` syncs against a keypoint nobody reads).
      expect(states, hasLength(1));
      expect(states.single.selectedLesson.id, 'lesson-2');
      expect(states.single.resolvedCurrentKeypoint.id, 'kp-9');

      await subscription.cancel();
      await cubit.close();
    });

    test('ignores a call with no lesson or no keypoint', () async {
      final cubit = CourseLessonCubit(
        GetCourseLessonUseCase(_FakeCourseLessonRepository((id) => TaskEither.right(lessonOf(id)))),
        _FakeRemoteConfigService(),
      );
      cubit.setSelectedLesson(lessonOf('lesson-1', keypointId: 'kp-1'));

      cubit.enterLesson(lesson: const LessonEntity(), keypointId: 'kp-9');
      cubit.enterLesson(lesson: lessonOf('lesson-2', keypointId: 'kp-9'), keypointId: '');

      expect(cubit.state.selectedLesson.id, 'lesson-1');
      await cubit.close();
    });
  });
}
