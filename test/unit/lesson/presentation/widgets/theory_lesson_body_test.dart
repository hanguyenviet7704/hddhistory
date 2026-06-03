import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('disables the continue CTA until an explanation option is selected', (tester) async {
    final cubit = _TestTheoryCubit(
      TheoryState(
        status: TheoryStatus.success,
        currentLearningItem: _buildTheoryLearningItem(
          documents: const [
            DocumentEntity(
              id: 1,
              document: [
                ContentDocumentEntity(
                  id: 11,
                  type: ContentDocumentType.explanation,
                  data: DocumentDataEntity(
                    content: BaseMultiLanguage(en: 'Pick one'),
                    options: [
                      ExplanationOptionEntity(
                        id: 1,
                        value: BaseMultiLanguage(en: 'Option A'),
                        explanation: BaseMultiLanguage(en: 'Explanation A'),
                      ),
                      ExplanationOptionEntity(
                        id: 2,
                        value: BaseMultiLanguage(en: 'Option B'),
                        explanation: BaseMultiLanguage(en: 'Explanation B'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildTheoryBody(cubit));
    await tester.pumpAndSettle();

    expect(_continueButton(tester).isEnabled, isFalse);

    await tester.tap(find.byKey(const ValueKey('document-explanation-card-0')));
    await tester.pumpAndSettle();

    expect(_continueButton(tester).isEnabled, isTrue);
  });

  testWidgets('keeps the continue CTA enabled when the theory document has no explanation options', (tester) async {
    final cubit = _TestTheoryCubit(
      TheoryState(
        status: TheoryStatus.success,
        currentLearningItem: _buildTheoryLearningItem(
          documents: const [
            DocumentEntity(
              id: 1,
              document: [
                ContentDocumentEntity(
                  id: 11,
                  type: ContentDocumentType.text,
                  data: DocumentDataEntity(
                    content: BaseMultiLanguage(en: 'Plain theory content'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildTheoryBody(cubit));
    await tester.pumpAndSettle();

    expect(_continueButton(tester).isEnabled, isTrue);
  });

  testWidgets('wraps theory documents in the shared Figma content card', (tester) async {
    final cubit = _TestTheoryCubit(
      TheoryState(
        status: TheoryStatus.success,
        currentLearningItem: _buildTheoryLearningItem(
          documents: const [
            DocumentEntity(
              id: 1,
              document: [
                ContentDocumentEntity(
                  id: 11,
                  type: ContentDocumentType.text,
                  data: DocumentDataEntity(
                    content: BaseMultiLanguage(en: 'Theory content'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildTheoryBody(cubit));
    await tester.pumpAndSettle();

    expect(find.byType(LessonContentCard), findsOneWidget);
    expect(find.text('Theory content'), findsOneWidget);
  });

  testWidgets('lets active theory cards fill the scoped lesson viewport height', (tester) async {
    final cubit = _TestTheoryCubit(
      TheoryState(
        status: TheoryStatus.success,
        currentLearningItem: _buildTheoryLearningItem(
          documents: const [
            DocumentEntity(
              id: 1,
              document: [
                ContentDocumentEntity(
                  id: 11,
                  type: ContentDocumentType.text,
                  data: DocumentDataEntity(
                    content: BaseMultiLanguage(en: 'Short theory content'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildTheoryBody(cubit, minCardHeight: 500));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(LessonContentCard)).height, greaterThanOrEqualTo(500));
  });
}

Widget _buildTheoryBody(
  TheoryCubit cubit, {
  double? minCardHeight,
}) {
  final body = TheoryLessonBody(onAnswerChecked: (_) {});

  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TranslationProvider(
      child: MaterialApp(
        home: BlocProvider<TheoryCubit>.value(
          value: cubit,
          child: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: minCardHeight == null
                        ? body
                        : LessonCardMinHeightScope(
                            minHeight: minCardHeight,
                            child: body,
                          ),
                  ),
                  body.buildBottomButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

ExerciseContinueButton _continueButton(WidgetTester tester) {
  return tester.widget<ExerciseContinueButton>(find.byType(ExerciseContinueButton));
}

LearningItemEntity _buildTheoryLearningItem({
  required List<DocumentEntity> documents,
}) {
  return LearningItemEntity(
    id: 'learning-item-1',
    type: LearningItemType.theory,
    documents: documents,
  );
}

class _TestTheoryCubit extends TheoryCubit {
  _TestTheoryCubit(TheoryState initialState) : super(_FakeGetLearningItemUseCase()) {
    emit(initialState);
  }
}

class _FakeGetLearningItemUseCase implements GetLearningItemUseCase {
  @override
  TaskEither<AppException, LearningItemEntity> call(String params) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
