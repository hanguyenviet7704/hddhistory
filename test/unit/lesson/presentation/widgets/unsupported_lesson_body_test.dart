import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  setUpAll(() async {
    await setupLocaleCubitForTests();
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  group('UnsupportedLessonBody', () {
    testWidgets('shows unsupported raw type label', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      const question = QuestionEntity(
        typedPayload: QuestionPayloadEntity.unsupported(rawType: 'single_choice_unknown'),
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => TranslationProvider(
            child: MaterialApp(
              home: Scaffold(body: child),
            ),
          ),
          child: const UnsupportedLessonBody(question: question),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Type: single_choice_unknown'), findsOneWidget);
    });
  });
}
