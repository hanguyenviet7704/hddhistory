import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  setUpAll(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  Widget buildTestableWidget(Widget child) {
    final navigatorKey = AppConfig.instance.rootNaviKey;
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => TranslationProvider(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(body: child),
        ),
      ),
      child: child,
    );
  }

  group('OnboardBranching widgets', () {
    testWidgets('P2 option view keeps continue disabled when gating is false', (tester) async {
      AppConfig.instance.rootNaviKey = GlobalKey<NavigatorState>();
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          OnboardBranchingOptionContentView(
            title: 'Question',
            subTitle: 'Sub question',
            options: const [
              OnboardBranchingOptionDisplayItem(id: '1', label: 'Option A'),
            ],
            selectedOptionId: null,
            onSelect: (_) {},
            onContinue: () {},
            continueEnabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('P8 person admire select keeps continue disabled when gating is false', (tester) async {
      AppConfig.instance.rootNaviKey = GlobalKey<NavigatorState>();
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          OnboardBranchingPersonAdmireSelectView(
            question: 'Who do you admire?',
            subQuestion: 'Pick one',
            options: const [
              OnboardingScenarioPersonOptionEntity(
                name: 'Person 1',
                title: BaseMultiLanguage(en: 'Title'),
                subTitle: BaseMultiLanguage(en: 'Sub title'),
              ),
            ],
            selectedOptionName: null,
            onSelect: (_) {},
            onContinue: () {},
            continueEnabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('P6 loading view triggers completion once after timer', (tester) async {
      AppConfig.instance.rootNaviKey = GlobalKey<NavigatorState>();
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var completedCount = 0;

      await tester.pumpWidget(
        buildTestableWidget(
          OnboardBranchingLoadingView(
            onCompleted: () {
              completedCount += 1;
            },
          ),
        ),
      );

      expect(completedCount, 0);
      await tester.pump(const Duration(seconds: 3));
      expect(completedCount, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(completedCount, 1);
    });
  });
}
