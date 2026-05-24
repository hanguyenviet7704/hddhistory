import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('Daily warm-up P2 widgets', () {
    testWidgets('progress dots render one dot per usable question without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_harness(const DailyWarmUpProgressDots(count: 8, currentIndex: 2)));

      expect(find.byType(AnimatedContainer), findsNWidgets(8));
      expect(tester.takeException(), isNull);
    });

    testWidgets('bottom CTA is disabled until a valid answer exists', (tester) async {
      var tapped = false;
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          DailyWarmUpBottomCta(
            label: 'Check',
            enabled: false,
            onPressed: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(tapped, isFalse);
    });
  });
}

Widget _harness(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => TranslationProvider(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}
