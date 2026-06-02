import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

const _noCorrectQuestion = QuestionEntity(
  id: 801,
  exerciseId: 'exercise-801',
  typedPayload: QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
    options: [
      QuestionNoCorrectChoiceOptionEntity(
        value: BaseMultiLanguage(en: 'Option A'),
        documentGroupId: 'group-a',
      ),
    ],
    documentGroups: [
      QuestionNoCorrectDocumentGroupEntity(
        id: 'group-a',
        documents: [
          ContentDocumentEntity(
            type: ContentDocumentType.text,
            data: DocumentDataEntity(content: BaseMultiLanguage(en: 'Document page content')),
          ),
        ],
      ),
    ],
  ),
);

const _noCorrectQuestionWithExplanationDocument = QuestionEntity(
  id: 802,
  exerciseId: 'exercise-802',
  typedPayload: QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
    options: [
      QuestionNoCorrectChoiceOptionEntity(
        value: BaseMultiLanguage(en: 'Option B'),
        documentGroupId: 'group-b',
      ),
    ],
    documentGroups: [
      QuestionNoCorrectDocumentGroupEntity(
        id: 'group-b',
        documents: [
          ContentDocumentEntity(
            type: ContentDocumentType.explanation,
            data: DocumentDataEntity(
              content: BaseMultiLanguage(en: 'Explanation title'),
              options: [
                ExplanationOptionEntity(
                  value: BaseMultiLanguage(en: 'Explanation option'),
                  explanation: BaseMultiLanguage(en: 'Explanation detail'),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupLocaleCubitForTests();
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  testWidgets('renders scaffold and list view with continue button without LessonLayout', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.en);

    final choiceCubit = ChoiceCubit()..setQuestion(_noCorrectQuestion);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp(
            home: BlocProvider<ChoiceCubit>.value(
              value: choiceCubit,
              child: const NoCorrectAnswerDocumentPage(groupId: 'group-a'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(LessonLayout), findsNothing);
    expect(find.byType(LessonContentCard), findsNothing);
    expect(find.byType(ExerciseContinueButton), findsOneWidget);
    expect(find.text('Document page content'), findsOneWidget);

    await choiceCubit.close();
  });

  testWidgets('renders explanation documents through shared document page path', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.en);

    final choiceCubit = ChoiceCubit()..setQuestion(_noCorrectQuestionWithExplanationDocument);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp(
            home: BlocProvider<ChoiceCubit>.value(
              value: choiceCubit,
              child: const NoCorrectAnswerDocumentPage(groupId: 'group-b'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Explanation title'), findsOneWidget);
    expect(find.text('Explanation option'), findsOneWidget);
    expect(find.text('Explanation detail'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('document-explanation-card-0')));
    await tester.pumpAndSettle();

    expect(find.text('Explanation detail'), findsOneWidget);

    await choiceCubit.close();
  });
}
