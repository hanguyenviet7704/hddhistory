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

  group('RoleplayExerciseAnswerCard', () {
    testWidgets('renders selected answer for single_choice_no_correct_answer', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.vi);

      const question = QuestionEntity(
        id: 201,
        exerciseId: 'exercise-201',
        typedPayload: QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
          options: [
            QuestionNoCorrectChoiceOptionEntity(value: BaseMultiLanguage(en: 'A')),
            QuestionNoCorrectChoiceOptionEntity(value: BaseMultiLanguage(en: 'B')),
          ],
        ),
        result: ExerciseResultEntity(
          passed: true,
          singleAnswer: OptionEntity(
            value: BaseMultiLanguage(en: 'Selected no-correct answer'),
          ),
        ),
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
          child: const RoleplayExerciseAnswerCard(exercise: question),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selected no-correct answer'), findsOneWidget);
    });
  });
}
