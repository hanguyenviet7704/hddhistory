import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../../../../support/test_di.dart';

const _options = [
  ExplanationOptionEntity(
    id: 0,
    value: BaseMultiLanguage(en: 'Option A'),
    explanation: BaseMultiLanguage(en: 'Explanation A'),
  ),
  ExplanationOptionEntity(
    id: 0,
    value: BaseMultiLanguage(en: 'Option B'),
    explanation: BaseMultiLanguage(en: 'Explanation B'),
  ),
];

const _replacementOptions = [
  ExplanationOptionEntity(
    id: 0,
    value: BaseMultiLanguage(en: 'Option C'),
    explanation: BaseMultiLanguage(en: 'Explanation C'),
  ),
  ExplanationOptionEntity(
    id: 0,
    value: BaseMultiLanguage(en: 'Option D'),
    explanation: BaseMultiLanguage(en: 'Explanation D'),
  ),
];

const _firstExplanationDocument = ContentDocumentEntity(
  id: 1,
  type: ContentDocumentType.explanation,
  data: DocumentDataEntity(options: _options),
);

const _secondExplanationDocument = ContentDocumentEntity(
  id: 2,
  type: ContentDocumentType.explanation,
  data: DocumentDataEntity(options: _options),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupLocaleCubitForTests();
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  testWidgets('expands, collapses, and switches explanation options locally', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.vi);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: const MaterialApp(
            home: Scaffold(
              body: DocumentExplanationWidget(
                title: 'Explanation title',
                options: _options,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('document-explanation-title')), findsOneWidget);
    expect(find.text('Explanation title'), findsOneWidget);
    expect(find.text('Explanation A'), findsNothing);
    expect(find.text('Explanation B'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('document-explanation-card-0')));
    await tester.pumpAndSettle();

    expect(find.text('Explanation A'), findsOneWidget);
    expect(find.text('Explanation B'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('document-explanation-card-0')));
    await tester.pumpAndSettle();

    expect(find.text('Explanation A'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('document-explanation-card-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('document-explanation-card-1')));
    await tester.pumpAndSettle();

    expect(find.text('Explanation A'), findsNothing);
    expect(find.text('Explanation B'), findsOneWidget);
  });

  testWidgets('does not render title when title is empty', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.vi);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: const MaterialApp(
            home: Scaffold(
              body: DocumentExplanationWidget(options: _options),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('document-explanation-title')), findsNothing);
  });

  testWidgets('resets local selection when options are replaced with a different document', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.vi);

    Widget buildWidget(List<ExplanationOptionEntity> options) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentExplanationWidget(options: options),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildWidget(_options));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('document-explanation-card-0')));
    await tester.pumpAndSettle();

    expect(find.text('Explanation A'), findsOneWidget);

    await tester.pumpWidget(buildWidget(_replacementOptions));
    await tester.pumpAndSettle();

    expect(find.text('Explanation A'), findsNothing);
    expect(find.text('Explanation C'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('document-explanation-card-0')));
    await tester.pumpAndSettle();

    expect(find.text('Explanation C'), findsOneWidget);
  });

  testWidgets('does not leak selection across explanation documents with identical options', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.vi);

    Widget buildWidget(ContentDocumentEntity document) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: DocumentItem(document: document),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildWidget(_firstExplanationDocument));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('document-explanation-card-0')));
    await tester.pumpAndSettle();

    expect(find.text('Explanation A'), findsOneWidget);

    await tester.pumpWidget(buildWidget(_secondExplanationDocument));
    await tester.pumpAndSettle();

    expect(find.text('Explanation A'), findsNothing);
  });
}
