import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('LessonAudioCubit', () {
    test('marks keypoints without resolved audio as unavailable', () async {
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(
        const KeypointEntity(
          id: 'keypoint-1',
          title: BaseMultiLanguage(en: 'Greetings'),
        ),
      );

      expect(cubit.state.status, LessonAudioLoadStatus.unavailable);
      expect(cubit.state.keypointId, 'keypoint-1');
      expect(cubit.state.sourceUrl, isEmpty);
      expect(cubit.state.title, 'Greetings');
      expect(cubit.state.hasUsableSource, isFalse);
    });

    test('resets configured audio session state without dropping the source metadata', () async {
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(_audioKeypoint());
      await cubit.setSpeed(1.25);
      await cubit.resetSession();

      expect(cubit.state.status, LessonAudioLoadStatus.initial);
      expect(cubit.state.keypointId, 'keypoint-1');
      expect(cubit.state.sourceUrl, 'https://audio.example/track.mp3');
      expect(cubit.state.speed, 1.0);
      expect(cubit.state.positionSeconds, 0);
      expect(cubit.state.durationSeconds, 0);
      expect(cubit.state.hasStartedSession, isFalse);
      expect(cubit.state.hasCompletedPlayback, isFalse);
    });

    test('ignores unsupported speed values before playback starts', () async {
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(_audioKeypoint());
      await cubit.setSpeed(1.1);

      expect(cubit.state.speed, 1.0);
    });
  });
}

KeypointEntity _audioKeypoint() {
  return const KeypointEntity(
    id: 'keypoint-1',
    title: BaseMultiLanguage(en: 'Greetings'),
    audio: KeypointAudioEntity(
      url: BaseMultiLanguage(en: 'https://audio.example/track.mp3'),
    ),
  );
}
