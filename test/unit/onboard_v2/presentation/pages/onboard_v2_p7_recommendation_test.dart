import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';
import 'package:mockito/mockito.dart';

import '../../../../support/test_di.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

class _MockUserCubit extends Mock implements UserCubit {}

class _NoopTrackingService extends BaseTrackingService {}

class _FakeDeviceInfoService implements IDeviceInfoService {
  @override
  Future<BaseDeviceInfo?> get deviceInfo async => null;

  @override
  Future<String> get deviceName async => 'iPhone';

  @override
  Future<String> get deviceToken async => 'device-token';

  @override
  Future<void> getAllDeviceInfo() async {}

  @override
  Future<int?> getAndroidSdkVersion() async => null;

  @override
  Future<bool> isAndroid13OrHigher() async => false;
}

class _FakeOnboardRepository implements IOnboardRepository {
  @override
  TaskEither<AppException, OnboardEntity> getAllOnboards() => TaskEither.right(const OnboardEntity());

  @override
  TaskEither<AppException, UserEntity> getUserByDeviceId(String deviceId) => TaskEither.right(const UserEntity());
}

class _FakeProfileRepository implements IProfileRepository {
  @override
  TaskEither<AppException, UserEntity> getUser(String id) => TaskEither.right(const UserEntity());

  @override
  TaskEither<AppException, UserEntity> updateUser(Map<String, dynamic> params) => TaskEither.right(const UserEntity());
}

class _FakeCourseRepository implements ICourseRepository {
  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(PageBreakRequest<CourseFilterRequest> request) {
    return TaskEither.right(BasePageBreak<CourseEntity>());
  }

  @override
  TaskEither<AppException, CourseEntity> getCourse(String id) => TaskEither.right(CourseEntity(id: id, numberOfLesson: 1));

  @override
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id) => TaskEither.right(const RoadmapEntity());
}

class _SeededOnboardV2Cubit extends OnboardV2Cubit {
  _SeededOnboardV2Cubit()
    : super.withRandom(
        GetAllOnboardsUseCase(_FakeOnboardRepository()),
        UpdateUserUseCase(_FakeProfileRepository()),
        GetAllCoursesUseCase(_FakeCourseRepository()),
        GetCourseUseCase(_FakeCourseRepository()),
        _FakeDeviceInfoService(),
        _MockAuthBloc(),
        _MockUserCubit(),
        AppDI.injector.get<LocaleCubit>(),
        Random(0),
      );

  void seed(OnboardV2State state) => emit(state);
}

class _SpyOnboardV2Cubit extends _SeededOnboardV2Cubit {
  int markOnboardedCount = 0;

  @override
  void markUserOnboardedInBackground() {
    markOnboardedCount += 1;
  }
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    AppConfig.instance.rootNaviKey = GlobalKey<NavigatorState>();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('P7 renders merged symptoms and disables CTA until one is selected', (tester) async {
    await _setPhoneSurface(tester);
    final cubit = _SeededOnboardV2Cubit()
      ..seed(
        OnboardV2State(
          currentPage: OnboardV2PageStep.p7Symptoms,
          selectedPaths: const [OnboardingPath.workBetter],
          availableSymptoms: OnboardV2SymptomSelectionMapper.availableSymptoms(const [OnboardingPath.workBetter]),
        ),
      );
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildSymptomPage(cubit));
    await tester.pumpAndSettle();

    expect(find.text(OnboardingSymptom.difficultyBuildingHabits.title), findsOneWidget);
    expect(find.text(OnboardingSymptom.timeSlipsAway.title), findsOneWidget);
    expect(find.text(OnboardingSymptom.strugglingToBreakBadHabits.title), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byKey(const Key('onboard_v2_primary_cta'))).onPressed, isNull);

    await tester.tap(find.text(OnboardingSymptom.timeSlipsAway.title));
    await tester.pump();

    expect(cubit.state.selectedSymptoms, [OnboardingSymptom.timeSlipsAway]);
    expect(tester.widget<ElevatedButton>(find.byKey(const Key('onboard_v2_primary_cta'))).onPressed, isNotNull);
  });

  testWidgets('P8 loaded courses render carousel and CTA uses current visible course', (tester) async {
    await _setPhoneSurface(tester);
    final cubit = _SeededOnboardV2Cubit()
      ..seed(
        const OnboardV2State(
          currentPage: OnboardV2PageStep.p8CoursePicker,
          courseStatus: OnboardV2CourseStatus.loaded,
          recommendedCourses: [
            CourseEntity(
              id: 'course_1',
              title: BaseMultiLanguage(en: 'Focus Basics'),
              description: BaseMultiLanguage(en: 'A practical course for building steady routines and making useful progress every day.'),
              numberOfLesson: 1,
            ),
            CourseEntity(
              id: 'course_2',
              title: BaseMultiLanguage(en: 'Better Habits'),
              numberOfLesson: 1,
            ),
          ],
        ),
      );
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildCoursePage(cubit));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('onboard_v2_course_picker_page_view')), findsOneWidget);
    expect(find.text('Focus Basics'), findsOneWidget);

    await tester.drag(find.byKey(const Key('onboard_v2_course_picker_page_view')), const Offset(-280, 0));
    await tester.pumpAndSettle();

    expect(cubit.state.currentCourseIndex, 1);
    expect(cubit.state.currentCourse?.id, 'course_2');
  });

  testWidgets('P8 fallback keeps retry/catalog actions and does not complete on view', (tester) async {
    await _setPhoneSurface(tester);
    final cubit = _SpyOnboardV2Cubit()
      ..seed(
        const OnboardV2State(
          currentPage: OnboardV2PageStep.p8CoursePicker,
          courseStatus: OnboardV2CourseStatus.fallback,
        ),
      );
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildCoursePage(cubit));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboard_v2_primary_cta')), findsOneWidget);
    expect(find.byKey(const Key('onboard_v2_secondary_cta')), findsOneWidget);
    expect(find.text('We could not load matches'), findsOneWidget);
    expect(cubit.markOnboardedCount, 0);
  });
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(375, 812);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _buildSymptomPage(OnboardV2Cubit cubit) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TranslationProvider(
      child: MaterialApp(
        home: BlocProvider<OnboardV2Cubit>.value(
          value: cubit,
          child: const OnboardV2SymptomSelectionPage(),
        ),
      ),
    ),
  );
}

Widget _buildCoursePage(OnboardV2Cubit cubit) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TranslationProvider(
      child: MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<OnboardV2Cubit>.value(value: cubit),
            BlocProvider<UserCubit>.value(value: UserCubit(_NoopTrackingService())),
          ],
          child: const OnboardV2CoursePickerPage(),
        ),
      ),
    ),
  );
}
