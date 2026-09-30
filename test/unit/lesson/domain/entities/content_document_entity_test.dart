import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupLocaleCubitForTests();
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  group('ContentDocumentEntity.dataAvailable', () {
    test('returns true for explanation documents backed by options only', () {
      LocaleSettings.setLocaleSync(AppLocale.vi);

      const document = ContentDocumentEntity(
        type: ContentDocumentType.explanation,
        data: DocumentDataEntity(
          options: [
            ExplanationOptionEntity(
              value: BaseMultiLanguage(en: 'Option A'),
            ),
          ],
        ),
      );

      expect(document.dataAvailable, isTrue);
    });

    test('keeps non-explanation empty documents hidden', () {
      LocaleSettings.setLocaleSync(AppLocale.vi);

      const document = ContentDocumentEntity(
        type: ContentDocumentType.text,
        data: DocumentDataEntity(),
      );

      expect(document.dataAvailable, isFalse);
    });
  });
}
