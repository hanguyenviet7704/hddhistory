import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

class _FakeUsageRepository implements IOutputPracticeRepository {
  _FakeUsageRepository(this.getUsageHandler);

  TaskEither<AppException, OutputPracticeConversationUsageEntity> Function(String sectionId) getUsageHandler;

  @override
  TaskEither<AppException, OutputPracticeConversationUsageEntity> getOutputPracticeConversationUsage(String sectionId) => getUsageHandler(sectionId);

  @override
  TaskEither<AppException, BasePageBreak<OutputPracticeMessageEntity>> getAllOutputPracticeMessages(OutputPracticeMessagesRequestEntity request) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> getOutputPracticeConversation(String sectionId) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> createOutputPracticeConversation(Map<String, dynamic> body) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, List<OutputPracticeMessageEntity>> sendOutputPracticeMessage(Map<String, dynamic> body) {
    throw UnimplementedError();
  }
}

class _FakeRemoteConfigService implements IRemoteConfigService {
  _FakeRemoteConfigService({required this.unlimitedEnabled});

  final bool unlimitedEnabled;

  @override
  AppVersionConfigEntity get appVersionConfig => const AppVersionConfigEntity();

  @override
  AppFunctionEntity get appFunction => const AppFunctionEntity();

  @override
  CourseConfigEntity get courseConfig => CourseConfigEntity(enablePremiumUnlimitedPractice: unlimitedEnabled);

  @override
  OnboardingConfigEntity get onboardingConfig => const OnboardingConfigEntity();

  @override
  PaywallConfigEntity get paywallConfig => const PaywallConfigEntity();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> shouldForceUpdate() async => false;

  @override
  Future<bool> optionalUpdateAvailable() async => false;
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('loads usage in the sheet and enables start only after the fetch resolves', (tester) async {
    final usageCompleter = Completer<Either<AppException, OutputPracticeConversationUsageEntity>>();
    AppDI.injector.registerSingleton<IRemoteConfigService>(_FakeRemoteConfigService(unlimitedEnabled: false));
    AppDI.injector.registerSingleton<GetOutputPracticeConversationUsageUseCase>(
      GetOutputPracticeConversationUsageUseCase(
        _FakeUsageRepository((_) => TaskEither(() async => await usageCompleter.future)),
      ),
    );

    var startCount = 0;
    await tester.pumpWidget(
      _buildTestShell(
        child: OutputPracticeIntroSheet(
          lesson: _lesson(),
          sectionId: 'section-1',
          isPremium: false,
          trackingData: null,
          onStart: () => startCount += 1,
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const ValueKey('output_practice_intro_usage_loading')), findsOneWidget);
    expect(find.text('Checking your monthly practice availability...'), findsNothing);

    await tester.tap(find.text('Start practice'), warnIfMissed: false);
    await tester.pump();
    expect(startCount, 0);

    usageCompleter.complete(right(const OutputPracticeConversationUsageEntity(remainingInThisMonth: 2, monthlyLimit: 5)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('output_practice_intro_usage_ready')), findsOneWidget);
    expect(find.text('2 practice left this month', findRichText: true), findsOneWidget);
    expect(find.textContaining('/5', findRichText: true), findsNothing);

    await tester.tap(find.text('Start practice'));
    await tester.pump();
    expect(startCount, 1);
  });

  testWidgets('tracks popup view/close/start from the modal lifecycle instead of the roadmap tap', (tester) async {
    final trackingBase = MockTrackingService();
    AppDI.injector.registerSingleton<ITrackingService>(AppTrackingService(trackingBase));
    AppDI.injector.registerSingleton<IRemoteConfigService>(_FakeRemoteConfigService(unlimitedEnabled: true));
    AppDI.injector.registerSingleton<GetOutputPracticeConversationUsageUseCase>(
      GetOutputPracticeConversationUsageUseCase(
        _FakeUsageRepository((_) => TaskEither.right(const OutputPracticeConversationUsageEntity(remainingInThisMonth: 99, monthlyLimit: 99))),
      ),
    );

    final trackingData = CourseLessonTrackingData(
      skillset: const SkillsetEntity(
        id: 'skill-1',
        title: BaseMultiLanguage(en: 'Speaking'),
      ),
      course: const CourseEntity(
        id: 'course-1',
        title: BaseMultiLanguage(en: 'English'),
        skillsetId: 'skill-1',
      ),
      lesson: _lesson(),
    );

    var startCount = 0;
    await tester.pumpWidget(
      _buildTestShell(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              OutputPracticeIntroSheet.show(
                context,
                lesson: _lesson(),
                sectionId: 'section-1',
                isPremium: true,
                trackingData: trackingData,
                onStart: () => startCount += 1,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(trackingBase.hasTrackedEvent(TrackingKey.outputPracticePopupView), isTrue);
    expect(trackingBase.hasTrackedEvent(TrackingKey.outputPracticePopupClose), isFalse);
    expect(trackingBase.hasTrackedEvent(TrackingKey.outputPracticeStartClick), isFalse);

    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();

    expect(startCount, 1);
    expect(trackingBase.hasTrackedEvent(TrackingKey.outputPracticeStartClick), isTrue);
    expect(trackingBase.hasTrackedEvent(TrackingKey.outputPracticePopupClose), isFalse);
  });
}

Widget _buildTestShell({required Widget child}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: child),
      ),
    ],
  );
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, widget) => TranslationProvider(
      child: MaterialApp.router(routerConfig: router),
    ),
    child: child,
  );
}

LessonEntity _lesson() => const LessonEntity(
  id: 'lesson-1',
  title: BaseMultiLanguage(en: 'Output practice'),
  description: BaseMultiLanguage(en: 'Practice speaking with the coach.'),
  courseId: 'course-1',
  type: LessonType.output,
);
