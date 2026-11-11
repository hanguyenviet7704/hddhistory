import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:hddhistory/hddhistory.dart';

import '../../../../support/test_di.dart';

/// The queue half of listening across keypoints: appending the next keypoint's
/// merged file behind the one playing, and what happens when the platform walks
/// into it. See `plans/260810-listen-across-keypoints/README.md`.
///
/// A scripted handler stands in for `just_audio`: the whole point of the design
/// is that the hop is driven by the platform moving between queue slots, so the
/// test drives exactly that — [_ScriptedHandler.moveToSlot].
class _ScriptedHandler extends Fake implements LessonAudioHandler {
  @override
  void Function()? onOsPause;
  @override
  void Function()? onOsPlay;

  final StreamController<just_audio.PlayerState> _playerState = StreamController.broadcast();
  final StreamController<Duration> _position = StreamController.broadcast();
  final StreamController<Duration?> _duration = StreamController.broadcast();
  final StreamController<just_audio.ProcessingState> _processing = StreamController.broadcast();
  final StreamController<int?> _slot = StreamController.broadcast();

  final List<String> appended = [];
  final List<Duration?> appendedDurations = [];
  final List<String> appendedAssets = [];
  int entryCues = 0;
  ({String id, String title, Duration? duration})? publishedItem;
  int dropTailCalls = 0;
  int slot = 0;

  @override
  Stream<just_audio.PlayerState> get playerStateStream => _playerState.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<just_audio.ProcessingState> get processingStateStream => _processing.stream;

  @override
  Stream<int?> get currentIndexStream => _slot.stream;

  @override
  int? get currentIndex => slot;

  @override
  Duration get position => Duration.zero;

  @override
  Future<Duration?> loadItem({
    required String url,
    required String id,
    required String title,
    required String artUri,
    double speed = 1.0,
    Duration? initialPosition,
    bool cacheToDisk = false,
  }) async => const Duration(seconds: 60);

  @override
  Future<void> appendItem({
    required String url,
    required String id,
    required String title,
    required String artUri,
    Duration? duration,
  }) async {
    appended.add(id);
    appendedDurations.add(duration);
  }

  @override
  Future<void> appendAssetItem({
    required String assetPath,
    required String id,
    required String title,
    required String artUri,
  }) async {
    appended.add(id);
    appendedDurations.add(null);
    appendedAssets.add(assetPath);
  }

  @override
  Future<void> playEntryCue() async {
    entryCues++;
  }

  @override
  Future<void> dropTailAfterCurrent() async {
    dropTailCalls++;
  }

  @override
  void publishMediaItem({required String id, required String title, required String artUri, Duration? duration}) {
    publishedItem = (id: id, title: title, duration: duration);
  }

  @override
  Future<void> playFromApp() async {}

  @override
  Future<void> pauseFromApp() async {}

  @override
  Future<void> pauseForSourceSwitch() async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  /// The platform finishing one queue item and starting the next.
  void moveToSlot(int next) {
    slot = next;
    _slot.add(next);
  }
}

void main() {
  late _ScriptedHandler handler;

  KeypointEntity keypoint(String id, {bool dubbed = true}) => KeypointEntity(
    id: id,
    title: BaseMultiLanguage(en: 'Title $id'),
    image: 'https://cdn.test/$id.png',
    audio: dubbed
        ? KeypointAudioEntity(
            merged: {
              'en': MergedKeypointAudioEntity(
                url: 'https://cdn.test/$id.mp3',
                durationMs: 60000,
                cues: [
                  MergedAudioCueEntity(learningItemId: '$id-item', documentIndex: 0, startMs: 0, durMs: 30000),
                  MergedAudioCueEntity(learningItemId: '$id-item', documentIndex: 1, startMs: 30000, durMs: 30000),
                ],
              ),
            },
          )
        : null,
  );

  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
    handler = _ScriptedHandler();
    AppDI.injector.unregister<LessonAudioHandler>();
    AppDI.injector.registerSingleton<LessonAudioHandler>(handler);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  Future<LessonAudioCubit> startedOn(KeypointEntity keypoint) async {
    final cubit = LessonAudioCubit();
    addTearDown(cubit.close);
    await cubit.configure(keypoint);
    await cubit.enterAudioMode(autoplay: false);
    expect(cubit.state.isReady, isTrue, reason: 'the session must be live before a keypoint can be queued behind it');
    return cubit;
  }

  group('LessonAudioCubit chain', () {
    test('queues the next keypoint behind the one playing', () async {
      final cubit = await startedOn(keypoint('kp-1'));

      expect(await cubit.appendKeypoint(keypoint('kp-2')), isTrue);
      // Đoạn chuyển tiếp đứng trước file merged: ngắt + chime (asset), rồi
      // merged. Keypoint test này chưa có clip "Tiếp theo" nên không có slot đó.
      expect(handler.appended, ['kp-2-gap', 'kp-2-chime', 'kp-2']);
      expect(handler.appendedAssets, ['assets/audio/narration_gap.m4a', 'assets/audio/keypoint_chime.m4a']);
      // The whole-file length rides along from the cue map, so the lock screen
      // keeps a scrubber total across the hop.
      expect(handler.appendedDurations.last, const Duration(milliseconds: 60000));
      expect(cubit.hasQueuedNext, isTrue);
      // The keypoint playing is untouched — that is the whole point of appending
      // rather than switching sources.
      expect(cubit.state.keypointId, 'kp-1');
    });

    test('walking into the queued slot becomes that keypoint and fires a hop', () async {
      final cubit = await startedOn(keypoint('kp-1'));
      await cubit.appendKeypoint(keypoint('kp-2'));

      final hop = expectLater(cubit.keypointHops, emits((from: 'kp-1', to: 'kp-2')));
      // Slot 1-2 là ngắt + chime: đi qua chúng KHÔNG được adopt — cue map của
      // kp-2 mà gán cho đoạn chime là position rác. Merged nằm ở slot 3.
      handler.moveToSlot(1);
      handler.moveToSlot(2);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.keypointId, 'kp-1', reason: 'prelude slots must not adopt');
      handler.moveToSlot(3);
      await hop;

      expect(cubit.state.keypointId, 'kp-2');
      expect(cubit.state.title, 'Title kp-2');
      expect(cubit.state.imageUrl, 'https://cdn.test/kp-2.png');
      // The lock screen is renamed to the keypoint now being read.
      expect(handler.publishedItem?.id, 'kp-2');
      expect(handler.publishedItem?.title, 'Title kp-2');
      expect(handler.publishedItem?.duration, const Duration(milliseconds: 60000));
      expect(cubit.state.isPlaying, isTrue);
      expect(cubit.state.activeCueIndex, 0);
      // Position is per queue item, so the new keypoint starts at its own zero.
      expect(cubit.state.positionSeconds, 0);
      expect(cubit.state.durationSeconds, 30);
      // The tail is consumed: nothing is queued until the chain arms again.
      expect(cubit.hasQueuedNext, isFalse);
      // Cue math now answers for the NEW keypoint's cards.
      expect(cubit.cueForCard(learningItemId: 'kp-2-item', documentIndex: 1), 1);
      expect(cubit.cueForCard(learningItemId: 'kp-1-item', documentIndex: 1), isNull);
    });

    test('a same-keypoint refresh still upgrades a legacy session to merged mode', () async {
      // The regression that made the chain look broken on device (2026-08-10):
      // entry configures from the ROADMAP stub, which carries only the legacy
      // whole-keypoint url, and the merged file arrives seconds later as a
      // refresh for the SAME keypoint. Treating "this keypoint is playing" as
      // "the queue hopped into it" swallowed that refresh and left merged mode
      // off for every keypoint in the app.
      final stub = KeypointEntity(
        id: 'kp-1',
        title: BaseMultiLanguage(en: 'Title kp-1'),
        audio: KeypointAudioEntity(url: BaseMultiLanguage(en: 'https://cdn.test/legacy-kp-1.mp3')),
      );
      final cubit = await startedOn(stub);

      expect(cubit.isMergedMode, isFalse, reason: 'the stub has no cue map');
      expect(cubit.isPlayingKeypoint('kp-1'), isTrue);
      expect(cubit.isQueueHoppedKeypoint('kp-1'), isFalse, reason: 'nothing hopped — this session was loaded here');

      await cubit.configure(keypoint('kp-1'));

      expect(cubit.isMergedMode, isTrue);
      expect(cubit.cueForCard(learningItemId: 'kp-1-item', documentIndex: 1), 1);
    });

    test('marks a hopped-into keypoint as coming from the queue', () async {
      final cubit = await startedOn(keypoint('kp-1'));
      await cubit.appendKeypoint(keypoint('kp-2'));

      final hop = expectLater(cubit.keypointHops, emits((from: 'kp-1', to: 'kp-2')));
      handler.moveToSlot(3);
      await hop;

      expect(cubit.isQueueHoppedKeypoint('kp-2'), isTrue);
      expect(cubit.isQueueHoppedKeypoint('kp-1'), isFalse);
    });

    test('refuses to queue a keypoint twice, or one with no merged dub', () async {
      final cubit = await startedOn(keypoint('kp-1'));

      expect(await cubit.appendKeypoint(keypoint('kp-2')), isTrue);
      expect(await cubit.appendKeypoint(keypoint('kp-2')), isFalse);
      expect(await cubit.appendKeypoint(keypoint('kp-1')), isFalse, reason: 'the keypoint playing is not its own successor');
      expect(await cubit.appendKeypoint(keypoint('kp-3', dubbed: false)), isFalse);
      expect(handler.appended, ['kp-2-gap', 'kp-2-chime', 'kp-2']);
    });

    test('dropping the tail leaves the keypoint in flight alone', () async {
      final cubit = await startedOn(keypoint('kp-1'));
      await cubit.appendKeypoint(keypoint('kp-2'));

      await cubit.dropQueuedTail();

      expect(handler.dropTailCalls, 1);
      expect(cubit.hasQueuedNext, isFalse);
      expect(cubit.state.keypointId, 'kp-1');
      // A second call is a no-op rather than another platform round trip.
      await cubit.dropQueuedTail();
      expect(handler.dropTailCalls, 1);
    });

    test('a pause from the OS transport ends the chain', () async {
      final cubit = await startedOn(keypoint('kp-1'));
      await cubit.appendKeypoint(keypoint('kp-2'));

      handler.onOsPause?.call();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.pausedByUser, isTrue);
      expect(cubit.hasQueuedNext, isFalse);
      expect(handler.dropTailCalls, 1);
    });

    test('configuring another keypoint drops a tail queued for the old run', () async {
      final cubit = await startedOn(keypoint('kp-1'));
      await cubit.appendKeypoint(keypoint('kp-2'));

      await cubit.configure(keypoint('kp-9'));

      expect(cubit.hasQueuedNext, isFalse);
      // A slot change from the replaced playlist must not be mistaken for a hop.
      handler.moveToSlot(1);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.keypointId, 'kp-9');
    });
  });
}
