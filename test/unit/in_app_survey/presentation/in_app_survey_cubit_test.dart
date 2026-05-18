import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

class _FakeInAppSurveyRepository implements IInAppSurveyRepository {
  _FakeInAppSurveyRepository({required this.configResult, this.submitHandler});

  TaskEither<AppException, InAppSurveyConfigEntity> configResult;
  TaskEither<AppException, Unit> Function(InAppSurveyResponseEntity entity)? submitHandler;
  InAppSurveyResponseEntity? lastResponse;
  int submitCount = 0;

  @override
  TaskEither<AppException, InAppSurveyConfigEntity> getInAppSurveyConfig() => configResult;

  @override
  TaskEither<AppException, Unit> createInAppSurveyResponse(InAppSurveyResponseEntity entity) {
    submitCount += 1;
    lastResponse = entity;
    return submitHandler?.call(entity) ?? TaskEither.right(unit);
  }
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    AppDI.injector.registerSingleton<ITrackingService>(
      AppTrackingService(NoOpTrackingService()),
    );
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('InAppSurveyCubit', () {
    test('Given config failure, When loading, Then entry stays hidden', () async {
      final repository = _FakeInAppSurveyRepository(
        configResult: TaskEither.left(const AppException.unauthorized('unauthorized')),
      );
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadInAppSurveyConfig();

      expect(cubit.state.isEntryVisible, isFalse);
      expect(cubit.state.step, InAppSurveyStep.hidden);
    });

    test('Given empty branches, When loading, Then entry stays hidden', () async {
      final repository = _FakeInAppSurveyRepository(
        configResult: TaskEither.right(const InAppSurveyConfigEntity()),
      );
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadInAppSurveyConfig();

      expect(cubit.state.hasUsableConfig, isFalse);
      expect(cubit.state.isEntryVisible, isFalse);
    });

    test('Given usable config, When loading, Then entry becomes visible', () async {
      final repository = _FakeInAppSurveyRepository(configResult: TaskEither.right(_surveyConfig()));
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadInAppSurveyConfig();

      expect(cubit.state.hasUsableConfig, isTrue);
      expect(cubit.state.isEntryVisible, isTrue);
      expect(cubit.state.step, InAppSurveyStep.entry);
    });

    test('Given any popup step, When closing, Then draft resets and no response is submitted', () async {
      final repository = _FakeInAppSurveyRepository(configResult: TaskEither.right(_surveyConfig()));
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();

      cubit.openSurvey();
      cubit.closeSurvey();
      expect(cubit.state.step, InAppSurveyStep.entry);

      cubit.openSurvey();
      cubit.selectBranch(0);
      cubit.toggleOption('option-1');
      cubit.continueToOpenFeedback();
      cubit.updateFeedback('draft feedback');
      cubit.closeSurvey();

      expect(cubit.state.selectedBranchIndex, isNull);
      expect(cubit.state.selectedOptionIds, isEmpty);
      expect(cubit.state.feedback, isEmpty);
      expect(cubit.state.isEntryVisible, isTrue);
      expect(repository.submitCount, 0);
    });

    test('Given single-choice branch, When selecting options, Then selection is replaced', () async {
      final repository = _FakeInAppSurveyRepository(configResult: TaskEither.right(_surveyConfig()));
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();

      cubit.openSurvey();
      cubit.selectBranch(0);
      cubit.toggleOption('option-1');
      cubit.toggleOption('option-2');

      expect(cubit.state.selectedOptionIds, ['option-2']);
      expect(cubit.state.canContinueClosedQuestion, isTrue);
    });

    test('Given rating step, When selecting branch by index, Then matching branch is selected', () async {
      final repository = _FakeInAppSurveyRepository(configResult: TaskEither.right(_surveyConfig()));
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();

      cubit.openSurvey();
      cubit.selectBranch(1);

      expect(cubit.state.selectedBranchIndex, 1);
      expect(cubit.state.selectedBranch?.id, 'branch-2');
      expect(cubit.state.step, InAppSurveyStep.closedQuestion);
    });

    test('Given rating step, When selecting invalid branch index, Then state is unchanged', () async {
      final repository = _FakeInAppSurveyRepository(configResult: TaskEither.right(_surveyConfig()));
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();

      cubit.openSurvey();
      cubit.selectBranch(99);

      expect(cubit.state.selectedBranchIndex, isNull);
      expect(cubit.state.step, InAppSurveyStep.rating);
    });

    test('Given multiple-choice branch, When selecting options, Then options toggle on and off', () async {
      final repository = _FakeInAppSurveyRepository(
        configResult: TaskEither.right(_surveyConfig(type: InAppSurveyClosedQuestionType.multipleChoice)),
      );
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();

      cubit.openSurvey();
      cubit.selectBranch(0);
      cubit.toggleOption('option-1');
      cubit.toggleOption('option-2');
      cubit.toggleOption('option-1');

      expect(cubit.state.selectedOptionIds, ['option-2']);
    });

    test('Given closed-question step, When closing, Then no response is submitted', () async {
      final repository = _FakeInAppSurveyRepository(configResult: TaskEither.right(_surveyConfig()));
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.loadInAppSurveyConfig();

      cubit.openSurvey();
      cubit.selectBranch(0);
      cubit.closeSurvey();

      expect(cubit.state.step, InAppSurveyStep.entry);
      expect(cubit.state.selectedBranchIndex, isNull);
      expect(repository.submitCount, 0);
    });

    test('Given whitespace feedback, When submitting, Then payload sends empty feedback', () async {
      final repository = _FakeInAppSurveyRepository(configResult: TaskEither.right(_surveyConfig()));
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await _completeSurveyDraft(cubit, feedback: '   ');

      await cubit.submitSurveyResponse();

      expect(repository.lastResponse, isNotNull);
      expect(repository.lastResponse!.branchId, 'branch-1');
      expect(repository.lastResponse!.selectedOptionIds, ['option-1']);
      expect(repository.lastResponse!.feedback, '');
    });

    test('Given submit failure, When submitting, Then draft is preserved for retry', () async {
      final repository = _FakeInAppSurveyRepository(
        configResult: TaskEither.right(_surveyConfig()),
        submitHandler: (_) => TaskEither.left(const AppException.server('server failed')),
      );
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await _completeSurveyDraft(cubit, feedback: ' needs a faster load ');

      await cubit.submitSurveyResponse();

      expect(cubit.state.step, InAppSurveyStep.openFeedback);
      expect(cubit.state.selectedBranchIndex, 0);
      expect(cubit.state.selectedOptionIds, ['option-1']);
      expect(cubit.state.feedback, ' needs a faster load ');
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('Given submit success, When submitting, Then draft resets and entry remains visible', () async {
      final repository = _FakeInAppSurveyRepository(configResult: TaskEither.right(_surveyConfig()));
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await _completeSurveyDraft(cubit, feedback: 'Helpful');

      await cubit.submitSurveyResponse();

      expect(cubit.state.step, InAppSurveyStep.entry);
      expect(cubit.state.selectedBranchIndex, isNull);
      expect(cubit.state.selectedOptionIds, isEmpty);
      expect(cubit.state.feedback, isEmpty);
      expect(cubit.state.isEntryVisible, isTrue);
    });

    test('Given submit success, When opening survey again, Then a repeat submit can be sent', () async {
      final repository = _FakeInAppSurveyRepository(configResult: TaskEither.right(_surveyConfig()));
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await _completeSurveyDraft(cubit, feedback: 'First');

      await cubit.submitSurveyResponse();
      await _completeSurveyDraft(cubit, feedback: 'Second');
      await cubit.submitSurveyResponse();

      expect(repository.submitCount, 2);
      expect(repository.lastResponse?.feedback, 'Second');
      expect(cubit.state.isEntryVisible, isTrue);
    });

    test('Given submit in progress, When submit is tapped again, Then duplicate request is ignored', () async {
      final completer = Completer<Unit>();
      final repository = _FakeInAppSurveyRepository(
        configResult: TaskEither.right(_surveyConfig()),
        submitHandler: (_) => TaskEither(() async => right(await completer.future)),
      );
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await _completeSurveyDraft(cubit);

      final firstSubmit = cubit.submitSurveyResponse();
      final secondSubmit = cubit.submitSurveyResponse();
      await Future<void>.delayed(Duration.zero);

      expect(repository.submitCount, 1);
      completer.complete(unit);
      await firstSubmit;
      await secondSubmit;
      expect(repository.submitCount, 1);
    });
  });
}

InAppSurveyCubit _buildCubit(IInAppSurveyRepository repository) {
  return InAppSurveyCubit(
    GetInAppSurveyConfigUseCase(repository),
    CreateInAppSurveyResponseUseCase(repository),
  );
}

Future<void> _completeSurveyDraft(InAppSurveyCubit cubit, {String feedback = ''}) async {
  await cubit.loadInAppSurveyConfig();
  cubit.openSurvey();
  cubit.selectBranch(0);
  cubit.toggleOption('option-1');
  cubit.continueToOpenFeedback();
  cubit.updateFeedback(feedback);
}

InAppSurveyConfigEntity _surveyConfig({
  InAppSurveyClosedQuestionType type = InAppSurveyClosedQuestionType.singleChoice,
}) {
  return InAppSurveyConfigEntity(
    configKey: 'config-1',
    introQuestion: const InAppSurveyQuestionEntity(
      question: BaseMultiLanguage(en: 'How was your experience?'),
      guide: BaseMultiLanguage(en: 'Pick what feels right'),
    ),
    branches: [
      _branch(id: 'branch-1', index: 0, type: type),
      _branch(id: 'branch-2', index: 1, type: type),
    ],
  );
}

InAppSurveyBranchEntity _branch({
  required String id,
  required int index,
  required InAppSurveyClosedQuestionType type,
}) {
  return InAppSurveyBranchEntity(
    id: id,
    index: index,
    emoji: InAppSurveyEmojiEntity(name: 'emoji-$index', lightUrl: 'https://example.com/emoji-$index.png'),
    closedQuestion: InAppSurveyClosedQuestionEntity(
      question: const BaseMultiLanguage(en: 'What is not working?'),
      guide: const BaseMultiLanguage(en: 'Tap all that apply'),
      type: type,
      options: const [
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
    openQuestion: const InAppSurveyQuestionEntity(
      question: BaseMultiLanguage(en: 'What would bring you back?'),
    ),
  );
}
