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

    // "user sẽ phải chủ động tự bật" (2026-08-19): entries are silent, only the
    // reader's own play engages narration, and engagement is what LessonPage
    // consults to carry the voice onto the next keypoint. These run on
    // audio-LESS keypoints deliberately — enterAudioMode bails at `unavailable`
    // before any player I/O the [FakeLessonAudioHandler] cannot host, and the
    // flags under test are all written before that bail-out.
    test('starts un-engaged, and a silent bookmarked position-load does not engage', () async {
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(_silentKeypoint());
      expect(cubit.listenEngaged, isFalse);

      await cubit.enterAudioMode(autoplay: false, startAt: const Duration(seconds: 3));
      expect(cubit.listenEngaged, isFalse);
    });

    test("the reader's own play engages, and the flag survives configure onto the next keypoint", () async {
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(_silentKeypoint());
      await cubit.enterAudioMode();
      expect(cubit.listenEngaged, isTrue);

      // configure resets per-keypoint audio state but never the engagement —
      // that is the whole point: the voice keeps following once asked for.
      await cubit.configure(_silentKeypoint(id: 'keypoint-2'));
      expect(cubit.listenEngaged, isTrue);
    });

    test('chimes once on the first genuine play of a keypoint, not on re-entry', () async {
      final handler = AppDI.injector.get<LessonAudioHandler>() as FakeLessonAudioHandler;
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(_silentKeypoint());
      await cubit.enterAudioMode();
      await cubit.enterAudioMode();

      expect(handler.entryCues, 1);
    });

    test('a bookmarked position-load spends the entry chime — the later play continues without one', () async {
      final handler = AppDI.injector.get<LessonAudioHandler>() as FakeLessonAudioHandler;
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(_silentKeypoint());
      await cubit.enterAudioMode(autoplay: false, startAt: const Duration(seconds: 3));
      // The reader presses play mid-keypoint: a continuation, not a start.
      await cubit.enterAudioMode();

      expect(handler.entryCues, 0);
      expect(cubit.listenEngaged, isTrue);
    });

    test('a system play on a never-engaged session is refused outright', () async {
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      // A keypoint WITH audio on purpose: the refusal must land before the
      // no-session branch reaches enterAudioMode/_initializePlayer — the fake
      // handler would throw on any player I/O, so merely completing silently
      // proves none was attempted ("vào phát là không bật rồi nhưng lướt lại
      // bật", 2026-08-20 — forward-swipe carries funnel into play()).
      await cubit.configure(_audioKeypoint());
      await cubit.play();

      expect(cubit.listenEngaged, isFalse);
      expect(cubit.state.isPlaying, isFalse);
      expect(cubit.state.hasStartedSession, isFalse);
    });

    test('background read-on refuses a never-engaged session', () async {
      final cubit = LessonAudioCubit();
      addTearDown(cubit.close);

      await cubit.configure(_audioKeypoint());

      expect(await cubit.playRestOfKeypoint(), isFalse);
      expect(cubit.state.hasStartedSession, isFalse);
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

/// A keypoint with no dub at all — `enterAudioMode` on it stops at
/// `unavailable`, before any player I/O the fake handler would refuse.
KeypointEntity _silentKeypoint({String id = 'keypoint-1'}) {
  return KeypointEntity(
    id: id,
    title: const BaseMultiLanguage(en: 'Greetings'),
  );
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
