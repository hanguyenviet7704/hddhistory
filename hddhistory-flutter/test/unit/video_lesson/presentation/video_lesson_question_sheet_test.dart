import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('question sheet entrance animation does not throw with overshoot curves', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, widget) => TranslationProvider(
          child: MaterialApp(
            supportedLocales: AppLocaleUtils.supportedLocales,
            home: Scaffold(
              body: VideoLessonQuestionSheet(
                state: VideoLessonState.initial().copyWith(
                  currentQuestionPrompt: const VideoLessonQuestionPrompt(
                    question: QuestionEntity(),
                  ),
                ),
                onAnswerTap: (_) {},
                onSubmit: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
