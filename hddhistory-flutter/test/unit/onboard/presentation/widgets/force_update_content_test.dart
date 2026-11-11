import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  Widget buildSubject({VoidCallback? onUpdatePressed}) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => TranslationProvider(
        child: MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
      ),
      child: ForceUpdateContent(onUpdatePressed: onUpdatePressed),
    );
  }

  group('ForceUpdateContent', () {
    testWidgets('renders the localized copy and the decor asset', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text("We're getting better!"), findsOneWidget);
      expect(find.text('Update to unlock new features and a smoother experience.'), findsOneWidget);
      expect(find.text('Go to Update'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == AppAsset.images.app.forceUpdateDecor.path,
        ),
        findsOneWidget,
      );
    });

    testWidgets('forwards update taps', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      var updateTapCount = 0;
      await tester.pumpWidget(buildSubject(onUpdatePressed: () => updateTapCount += 1));
      await tester.pump();

      await tester.tap(find.text('Go to Update'));
      await tester.pump();

      expect(updateTapCount, 1);
    });

    testWidgets('refuses to pop — the back gesture must not dismiss a forced update', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });
  });

  // Asserted against the YAML rather than by rendering each locale: non-base
  // locales are deferred, and deferred loading is unavailable under `flutter
  // test` — setLocaleSync throws _DeferredNotLoadedError and setLocale never
  // completes. Reading the source of truth catches the failure that actually
  // matters (a locale missing a key falls back to English in silence, leaving a
  // blocking dialog in the wrong language with nothing to flag it).
  group('force update copy', () {
    const keys = ['forceUpdateTitle', 'forceUpdateMessage', 'forceUpdateAction'];

    for (final locale in ['en', 'vi', 'zh', 'ja', 'ko']) {
      test('$locale/common.yaml defines every force-update key', () {
        final yaml = File('assets/i18n/$locale/common.yaml').readAsStringSync();

        for (final key in keys) {
          final match = RegExp('^$key:[ ]*(.+)\$', multiLine: true).firstMatch(yaml);
          expect(match, isNotNull, reason: '$locale is missing $key');
          expect(match!.group(1)!.trim(), isNotEmpty, reason: '$locale has an empty $key');
        }
      });
    }

    test('vi carries real Vietnamese, not an untranslated placeholder', () {
      // Much of vi/common.yaml is still seeded with a "(VI) " prefix standing in
      // for untranslated English. A forced-update dialog is the worst place to
      // ship one of those.
      final yaml = File('assets/i18n/vi/common.yaml').readAsStringSync();

      for (final key in keys) {
        final value = RegExp('^$key:[ ]*(.+)\$', multiLine: true).firstMatch(yaml)!.group(1)!;
        expect(value.contains('(VI)'), isFalse, reason: 'vi $key is still an untranslated placeholder');
      }
    });
  });
}
