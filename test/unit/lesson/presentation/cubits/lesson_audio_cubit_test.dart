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

    test('a same-keypoint entity refresh keeps a pending listen intent', () async {
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(_audioKeypoint());
      // Entry's enterAudioMode registered the intent; its load is in flight.
      cubit.debugPlayWhenReady = true;

      // The full lesson payload lands over the roadmap stub: same keypoint,
      // different source. The reset must carry the intent across.
      await cubit.configure(_audioKeypoint(url: 'https://audio.example/merged.mp3'));
      expect(cubit.debugPlayWhenReady, isTrue);

      // A different keypoint starts from silence, as always.
      await cubit.configure(_audioKeypoint(id: 'keypoint-2', url: 'https://audio.example/other.mp3'));
      expect(cubit.debugPlayWhenReady, isFalse);
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

KeypointEntity _audioKeypoint({String id = 'keypoint-1', String url = 'https://audio.example/track.mp3'}) {
  return KeypointEntity(
    id: id,
    title: const BaseMultiLanguage(en: 'Greetings'),
    audio: KeypointAudioEntity(
      url: BaseMultiLanguage(en: url),
    ),
  );
}
