import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  tearDown(() async {
    await resetInjectorForTests();
  });

  group('KeypointEntity audio helpers', () {
    test('resolve audio url from locale fallback when the active locale is empty', () async {
      await setupLocaleCubitForTests(locale: AppLocale.vi);

      const keypoint = KeypointEntity(
        audio: KeypointAudioEntity(
          url: BaseMultiLanguage(en: 'https://audio.example/track.mp3'),
        ),
      );

      expect(keypoint.resolvedAudioUrl, 'https://audio.example/track.mp3');
      expect(keypoint.hasUsableAudio, isTrue);
    });

    test('treat blank audio urls as unusable', () async {
      await setupLocaleCubitForTests();

      const keypoint = KeypointEntity(
        audio: KeypointAudioEntity(
          url: BaseMultiLanguage(en: '   '),
        ),
      );

      expect(keypoint.resolvedAudioUrl, isEmpty);
      expect(keypoint.hasUsableAudio, isFalse);
    });
  });
}
