import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

class _FakeInAppSurveyRepository implements IInAppSurveyRepository {
  _FakeInAppSurveyRepository({required this.config});

  final InAppSurveyConfigEntity config;

  @override
  TaskEither<AppException, InAppSurveyConfigEntity> getInAppSurveyConfig() {
    return TaskEither.right(config);
  }

  @override
  TaskEither<AppException, Unit> createInAppSurveyResponse(InAppSurveyResponseEntity entity) {
    return TaskEither.right(unit);
  }
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
    AppDI.injector.registerSingleton<ITrackingService>(
      AppTrackingService(NoOpTrackingService()),
    );
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('InAppSurveyDialog', () {
    testWidgets('rating step shows dark emoji first and advances after selected emoji turns light', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cubit = _buildCubit();
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();
      cubit.openSurvey();

      await tester.pumpWidget(_buildHarness(cubit));
      await tester.pumpAndSettle();

      expect(cubit.state.step, InAppSurveyStep.rating);
      _expectNetworkImageUrls(
        tester,
        contains('https://example.com/emoji-0-dark.png'),
      );
      _expectNetworkImageUrls(
        tester,
        isNot(contains('https://example.com/emoji-0-light.png')),
      );

      await tester.ensureVisible(find.text('Awful'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Awful'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(cubit.state.step, InAppSurveyStep.rating);
      _expectNetworkImageUrls(
        tester,
        contains('https://example.com/emoji-0-light.png'),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(cubit.state.step, InAppSurveyStep.closedQuestion);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('closed question keeps Continue disabled until an option is selected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cubit = _buildCubit();
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();
      cubit.openSurvey();
      cubit.selectBranch(0);

      await tester.pumpWidget(_buildHarness(cubit));
      await tester.pumpAndSettle();

      expect(cubit.state.step, InAppSurveyStep.closedQuestion);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(cubit.state.step, InAppSurveyStep.closedQuestion);

      await tester.ensureVisible(find.text('Loads slowly'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Loads slowly'));
      await tester.pumpAndSettle();
      expect(cubit.state.selectedOptionIds, ['option-1']);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(cubit.state.step, InAppSurveyStep.openFeedback);
      expect(find.text('Send without feedback'), findsOneWidget);
    });

    testWidgets('open feedback CTA switches label when feedback is present', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cubit = _buildCubit();
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();
      cubit.openSurvey();
      cubit.selectBranch(0);
      cubit.toggleOption('option-1');
      cubit.continueToOpenFeedback();

      await tester.pumpWidget(_buildHarness(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Send without feedback'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'More focused lessons');
      await tester.pumpAndSettle();

      expect(cubit.state.feedback, 'More focused lessons');
      expect(find.text('Send feedback'), findsOneWidget);
    });

    testWidgets('renders gradient title span from backend HTML', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cubit = _buildCubit(
        config: _surveyConfig(
          introTitle: '<h1>How was <span data-gradient="survey-title">your experience</span> ?</h1>',
        ),
      );
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();
      cubit.openSurvey();

      await tester.pumpWidget(_buildHarness(cubit));
      await tester.pumpAndSettle();

      final title = _findSurveyTitleRichText('How was');
      expect(title, findsOneWidget);
      final gradientText = find.text('your experience');
      expect(gradientText, findsOneWidget);
      expect(find.ancestor(of: gradientText, matching: find.byType(ShaderMask)), findsOneWidget);
    });

    testWidgets('preserves leading whitespace inside gradient title span', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cubit = _buildCubit(
        config: _surveyConfig(
          openTitle: '''
<h1>
  What would 
<span data-gradient="survey-title"> bring you back</span> 
</h1>
''',
        ),
      );
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();
      cubit.openSurvey();
      cubit.selectBranch(0);
      cubit.toggleOption('option-1');
      cubit.continueToOpenFeedback();

      await tester.pumpWidget(_buildHarness(cubit));
      await tester.pumpAndSettle();

      expect(_findSurveyTitleRichText('What would'), findsOneWidget);
      expect(find.text(' bring you back'), findsOneWidget);
      expect(find.ancestor(of: find.text(' bring you back'), matching: find.byType(ShaderMask)), findsOneWidget);
    });

    testWidgets('collapses formatted backend HTML whitespace before layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cubit = _buildCubit(
        config: _surveyConfig(
          introTitle: '<h1>   How was <span data-gradient="survey-title">your experience</span> ? </h1>',
        ),
      );
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();
      cubit.openSurvey();

      await tester.pumpWidget(_buildHarness(cubit));
      await tester.pumpAndSettle();

      final titleFinder = _findSurveyTitleRichText('How was');
      expect(titleFinder, findsOneWidget);

      final titleWidget = tester.widget<RichText>(titleFinder);
      final titleParts = _textSpanParts(titleWidget.text);
      expect(titleParts, contains('How was '));
      expect(find.text('your experience'), findsOneWidget);
      expect(titleParts, contains(' ?'));

      final titleBox = tester.renderObject<RenderBox>(titleFinder);
      expect(titleBox.size.height, lessThan(80));
    });
  });
}

Finder _findSurveyTitleRichText(String text) {
  return find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText().contains(text),
  );
}

List<String> _textSpanParts(InlineSpan span) {
  if (span is! TextSpan) return const [];
  return [
    if (span.text != null) span.text!,
    ...?span.children?.expand(_textSpanParts),
  ];
}

Widget _buildHarness(InAppSurveyCubit cubit) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TranslationProvider(
      child: MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const InAppSurveyDialog(),
        ),
      ),
    ),
  );
}

void _expectNetworkImageUrls(WidgetTester tester, Matcher matcher) {
  final urls = tester.widgetList<Image>(find.byType(Image)).where((image) => image.image is NetworkImage).map((image) => (image.image as NetworkImage).url).toList();
  expect(urls, matcher);
}

InAppSurveyCubit _buildCubit({InAppSurveyConfigEntity? config}) {
  final repository = _FakeInAppSurveyRepository(config: config ?? _surveyConfig());
  return InAppSurveyCubit(
    GetInAppSurveyConfigUseCase(repository),
    CreateInAppSurveyResponseUseCase(repository),
  );
}

InAppSurveyConfigEntity _surveyConfig({
  String introTitle = 'How was your experience?',
  String openTitle = 'What would bring you back?',
}) {
  return InAppSurveyConfigEntity(
    configKey: 'config-1',
    introQuestion: InAppSurveyQuestionEntity(
      question: BaseMultiLanguage(en: introTitle),
      guide: const BaseMultiLanguage(en: 'Pick what feels right'),
    ),
    branches: [
      InAppSurveyBranchEntity(
        id: 'branch-1',
        index: 0,
        emoji: const InAppSurveyEmojiEntity(
          lightUrl: 'https://example.com/emoji-0-light.png',
          darkUrl: 'https://example.com/emoji-0-dark.png',
        ),
        closedQuestion: const InAppSurveyClosedQuestionEntity(
          question: BaseMultiLanguage(en: 'What is not working?'),
          guide: BaseMultiLanguage(en: 'Tap what applies'),
          type: InAppSurveyClosedQuestionType.singleChoice,
          options: [
            InAppSurveyOptionEntity(
              id: 'option-1',
              value: BaseMultiLanguage(en: 'Loads slowly'),
            ),
            InAppSurveyOptionEntity(
              id: 'option-2',
              value: BaseMultiLanguage(en: 'Hard to use'),
            ),
          ],
        ),
        openQuestion: InAppSurveyQuestionEntity(
          question: BaseMultiLanguage(en: openTitle),
        ),
      ),
    ],
  );
}
