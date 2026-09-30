import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('showLessonAudioSpeedSheet', () {
    testWidgets('keeps the preset buttons close to the bottom edge without extra spacing', (tester) async {
      _setPhoneViewport(tester);
      await LocaleSettings.setLocale(AppLocale.vi);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => TranslationProvider(
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(375, 812),
                  padding: EdgeInsets.only(bottom: 34),
                  viewPadding: EdgeInsets.only(bottom: 34),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
          child: const _LessonAudioSpeedSheetLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      final presetButton = find
          .ancestor(
            of: find.text('1.25x'),
            matching: find.byType(GestureDetector),
          )
          .first;
      final sheetSurface = find.byKey(const ValueKey('lesson-audio-speed-sheet-surface'));
      final screenBottom = tester.getRect(find.byType(Scaffold)).bottom;
      final surfaceBottom = tester.getRect(sheetSurface).bottom;
      final buttonBottom = tester.getRect(presetButton).bottom;

      expect(screenBottom - surfaceBottom, lessThanOrEqualTo(1));
      expect(surfaceBottom - buttonBottom, greaterThanOrEqualTo(34));
    });
  });
}

class _LessonAudioSpeedSheetLauncher extends StatefulWidget {
  const _LessonAudioSpeedSheetLauncher();

  @override
  State<_LessonAudioSpeedSheetLauncher> createState() => _LessonAudioSpeedSheetLauncherState();
}

class _LessonAudioSpeedSheetLauncherState extends State<_LessonAudioSpeedSheetLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showLessonAudioSpeedSheet(
        context,
        initialSpeed: 1.5,
        onSpeedChanged: (_) {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.expand(),
    );
  }
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(375, 812);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
