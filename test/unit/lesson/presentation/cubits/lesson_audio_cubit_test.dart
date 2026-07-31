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
    test('uses the active app locale for the configured audio title', () async {
      await resetInjectorForTests();
      await setupLocaleCubitForTests(locale: AppLocale.vi);

      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(
        const KeypointEntity(
          id: 'keypoint-1',
          title: BaseMultiLanguage(
            en: 'Greetings',
            vi: 'Xin chao',
          ),
        ),
      );

      expect(cubit.state.status, LessonAudioLoadStatus.unavailable);
      expect(cubit.state.keypointId, 'keypoint-1');
      expect(cubit.state.sourceUrl, isEmpty);
      expect(cubit.state.title, 'Xin chao');
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

    test('reports no narrated clip while the deck and the voice are in step', () async {
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(_audioKeypoint());

      // Nothing has read ahead, so there is nothing for the deck to catch up to —
      // and `narratingClipIndex` must say so rather than guess a slot.
      expect(cubit.isAheadOfDeck, isFalse);
      expect(cubit.narratingClipIndex, isNull);
    });

    test('has nothing to read on from when the keypoint has no per-card clips', () async {
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      // A legacy whole-keypoint dub: one `url`, no `segments`.
      await cubit.configure(_audioKeypoint());

      expect(cubit.hasCardClips, isFalse);
      expect(await cubit.playRestOfKeypoint(), isFalse);
      expect(cubit.narratingClipIndex, isNull);
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
