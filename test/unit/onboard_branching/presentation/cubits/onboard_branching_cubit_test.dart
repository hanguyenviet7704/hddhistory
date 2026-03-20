import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

class _FakeOnboardBranchingRepository implements IOnboardBranchingRepository {
  _FakeOnboardBranchingRepository(this._scenario);

  final OnboardingScenarioBranchingEntity _scenario;

  @override
  TaskEither<AppException, OnboardingScenarioBranchingEntity> getOnboardingScenarioBranching() {
    return TaskEither.right(_scenario);
  }
}

class _DelayedOnboardBranchingRepository implements IOnboardBranchingRepository {
  _DelayedOnboardBranchingRepository(this._scenario, this._delay);

  final OnboardingScenarioBranchingEntity _scenario;
  final Duration _delay;

  @override
  TaskEither<AppException, OnboardingScenarioBranchingEntity> getOnboardingScenarioBranching() {
    return TaskEither<AppException, OnboardingScenarioBranchingEntity>(() async {
      await Future<void>.delayed(_delay);
      return right(_scenario);
    });
  }
}

void main() {
  setUp(() async {
    await AppDI.injector.reset();
    AppDI.injector.registerSingleton<ITrackingService>(AppTrackingService(NoOpTrackingService()));
  });

  tearDown(() async {
    await AppDI.injector.reset();
  });

  test('moves from content -> loading -> recommendation deterministically', () async {
    const scenario = OnboardingScenarioBranchingEntity(
      entrySceneId: 'scene_1',
      scenes: [
        OnboardingScenarioSceneEntity(
          id: 'scene_1',
          contents: [
            OnboardingScenarioContentItemEntity(
              id: 1,
              type: OnboardingContentType.activation,
              activation: OnboardingScenarioActivationEntity(
                id: 1,
                title: BaseMultiLanguage(en: 'Activation title'),
                content: OnboardingScenarioActivationContentEntity(
                  labels: [
                    OnboardOptionEntity(
                      id: 1,
                      label: BaseMultiLanguage(en: 'Label 1'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final repository = _FakeOnboardBranchingRepository(scenario);
    final cubit = OnboardBranchingCubit(GetOnboardingScenarioBranchingUseCase(repository));

    await cubit.loadOnboardingScenarioBranching();
    cubit.startScenario();

    expect(cubit.state.stage, OnboardBranchingStage.content);
    expect(cubit.state.currentSceneId, 'scene_1');
    expect(cubit.state.currentContentIndex, 0);

    cubit.continueCurrentContent();
    expect(cubit.state.stage, OnboardBranchingStage.loading);

    cubit.onLoadingCompleted();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.stage, OnboardBranchingStage.recommendation);
    expect(cubit.state.isRecommendationInitialized, isTrue);

    await cubit.close();
  });

  test('recommendation picks the last valid course id after cleanup', () {
    const state = OnboardBranchingState(
      selectedBranchOptions: [
        OnboardingScenarioBranchOptionEntity(
          id: 1,
          courses: ['course_1', ' ', 'course_2'],
        ),
        OnboardingScenarioBranchOptionEntity(
          id: 2,
          courses: ['course_2', 'course_3', ''],
        ),
      ],
    );

    expect(state.recommendedCourseIds, ['course_1', 'course_2', 'course_3']);
    expect(state.recommendedCourseCandidateId, 'course_3');
  });

  test('initializeFlow resets previous runtime state for singleton re-entry', () async {
    const scenario = OnboardingScenarioBranchingEntity(
      entrySceneId: 'scene_1',
      scenes: [
        OnboardingScenarioSceneEntity(
          id: 'scene_1',
          contents: [
            OnboardingScenarioContentItemEntity(
              id: 1,
              type: OnboardingContentType.branch,
              branch: OnboardingScenarioBranchEntity(
                question: BaseMultiLanguage(en: 'Question'),
                subQuestion: BaseMultiLanguage(en: 'Sub question'),
                options: [
                  OnboardingScenarioBranchOptionEntity(
                    id: 1,
                    label: BaseMultiLanguage(en: 'Option 1'),
                    nextSceneId: '',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    final repository = _FakeOnboardBranchingRepository(scenario);
    final cubit = OnboardBranchingCubit(GetOnboardingScenarioBranchingUseCase(repository));

    await cubit.initializeFlow(userName: 'Alice');
    cubit.startScenario();

    final selectedOption = cubit.state.currentContent.branch!.options.first;
    cubit.selectBranchOption(selectedOption);
    cubit.continueCurrentContent();

    expect(cubit.state.stage, OnboardBranchingStage.loading);
    expect(cubit.state.selectedBranchOptions, isNotEmpty);

    await cubit.initializeFlow(userName: 'Bob');

    expect(cubit.state.stage, OnboardBranchingStage.welcome);
    expect(cubit.state.userName, 'Bob');
    expect(cubit.state.currentSceneId, isEmpty);
    expect(cubit.state.currentContentIndex, 0);
    expect(cubit.state.selectedBranchOptions, isEmpty);
    expect(cubit.state.selectedFixedOptions, isEmpty);
    expect(cubit.state.visitedSceneIds, isEmpty);
    expect(cubit.state.isOnboardingTransitionActive, isTrue);
    expect(cubit.state.fallbackReason, OnboardBranchingFallbackReason.none);

    await cubit.close();
  });

  test('continueFromWelcome does not fallback while scenario is still loading', () async {
    const scenario = OnboardingScenarioBranchingEntity(
      entrySceneId: 'scene_1',
      scenes: [
        OnboardingScenarioSceneEntity(
          id: 'scene_1',
          contents: [
            OnboardingScenarioContentItemEntity(
              id: 1,
              type: OnboardingContentType.activation,
              activation: OnboardingScenarioActivationEntity(
                id: 1,
                title: BaseMultiLanguage(en: 'Activation title'),
                content: OnboardingScenarioActivationContentEntity(
                  labels: [
                    OnboardOptionEntity(
                      id: 1,
                      label: BaseMultiLanguage(en: 'Label 1'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final repository = _DelayedOnboardBranchingRepository(scenario, const Duration(milliseconds: 120));
    final cubit = OnboardBranchingCubit(GetOnboardingScenarioBranchingUseCase(repository));

    final initFuture = cubit.initializeFlow(userName: 'Alice');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    cubit.continueFromWelcome();

    expect(cubit.state.fallbackReason, OnboardBranchingFallbackReason.none);
    expect(cubit.state.stage, OnboardBranchingStage.welcome);
    expect(cubit.state.isOnboardingTransitionActive, isTrue);

    await initFuture;
    await cubit.close();
  });

  test('clears selected person admire option when moving to next person admire content', () async {
    const scenario = OnboardingScenarioBranchingEntity(
      entrySceneId: 'scene_1',
      scenes: [
        OnboardingScenarioSceneEntity(
          id: 'scene_1',
          contents: [
            OnboardingScenarioContentItemEntity(
              id: 1,
              type: OnboardingContentType.personAdmire,
              personAdmire: OnboardingScenarioPersonAdmireEntity(
                question: BaseMultiLanguage(en: 'Question 1'),
                subQuestion: BaseMultiLanguage(en: 'Sub question 1'),
                options: [
                  OnboardingScenarioPersonOptionEntity(
                    name: 'person_1',
                    title: BaseMultiLanguage(en: 'Title 1'),
                    subTitle: BaseMultiLanguage(en: 'Sub title 1'),
                  ),
                ],
              ),
            ),
            OnboardingScenarioContentItemEntity(
              id: 2,
              type: OnboardingContentType.personAdmire,
              personAdmire: OnboardingScenarioPersonAdmireEntity(
                question: BaseMultiLanguage(en: 'Question 2'),
                subQuestion: BaseMultiLanguage(en: 'Sub question 2'),
                options: [
                  OnboardingScenarioPersonOptionEntity(
                    name: 'person_2',
                    title: BaseMultiLanguage(en: 'Title 2'),
                    subTitle: BaseMultiLanguage(en: 'Sub title 2'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    final repository = _FakeOnboardBranchingRepository(scenario);
    final cubit = OnboardBranchingCubit(GetOnboardingScenarioBranchingUseCase(repository));

    await cubit.loadOnboardingScenarioBranching();
    cubit.startScenario();

    final firstPerson = cubit.state.currentContent.personAdmire!.options.first;
    cubit.selectPersonAdmireOption(firstPerson);
    cubit.continueCurrentContent();
    expect(cubit.state.isPersonAdmireDetailVisible, isTrue);

    cubit.continueCurrentContent();

    expect(cubit.state.currentContentIndex, 1);
    expect(cubit.state.selectedPersonAdmireOption, isNull);
    expect(cubit.state.isPersonAdmireDetailVisible, isFalse);
    expect(cubit.state.canContinueCurrentContent, isFalse);

    await cubit.close();
  });
}
