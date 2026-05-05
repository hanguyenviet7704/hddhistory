import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('OnboardV2AgeTextResolver', () {
    test('uses localized label text first', () {
      const option = OnboardOptionEntity(
        id: 17,
        label: BaseMultiLanguage(en: '17 or younger'),
        title: BaseMultiLanguage(en: 'Teen'),
        trackingLabel: 'teen_tracking',
      );

      expect(OnboardV2AgeTextResolver.resolve(option), '17 or younger');
    });

    test('falls back to title text when label is blank', () {
      const option = OnboardOptionEntity(
        id: 18,
        title: BaseMultiLanguage(en: '18-24'),
        trackingLabel: 'adult_tracking',
      );

      expect(OnboardV2AgeTextResolver.resolve(option), '18-24');
    });

    test('falls back to tracking label when localized texts are blank', () {
      const option = OnboardOptionEntity(
        id: 25,
        trackingLabel: '25-34',
      );

      expect(OnboardV2AgeTextResolver.resolve(option), '25-34');
    });

    test('falls back to id string when all text fields are blank', () {
      const option = OnboardOptionEntity(id: 45);

      expect(OnboardV2AgeTextResolver.resolve(option), '45');
    });
  });
}
