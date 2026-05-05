import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';
import 'package:mockito/mockito.dart';

import '../../../../support/test_di.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

class _MockUserCubit extends Mock implements UserCubit {}

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

class _FakeHomeRepository implements IHomeRepository {
  @override
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> getAllSkillsets(PageBreakRequest<SkillsetFilterRequest> request) {
    return TaskEither.right(BasePageBreak<SkillsetEntity>());
  }

  @override
  TaskEither<AppException, SkillsetEntity> getSkillset(String id) => TaskEither.right(const SkillsetEntity());
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
  TaskEither<AppException, CourseEntity> getCourse(String id) => TaskEither.right(const CourseEntity());

  @override
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id) => TaskEither.right(const RoadmapEntity());
}

class _SeededOnboardV2Cubit extends OnboardV2Cubit {
  _SeededOnboardV2Cubit()
    : super.withRandom(
        GetAllOnboardsUseCase(_FakeOnboardRepository()),
        GetAllSkillsetsUseCase(_FakeHomeRepository()),
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

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
    AppConfig.instance.rootNaviKey = GlobalKey<NavigatorState>();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('loaded recommendation shows primary and secondary CTAs', (tester) async {
    final cubit = _SeededOnboardV2Cubit()
      ..seed(
        const OnboardV2State(
          currentPage: OnboardV2PageStep.p7Recommendation,
          recommendationStatus: OnboardV2RecommendationStatus.loaded,
          recommendedCourse: CourseEntity(
            id: 'course_1',
            title: BaseMultiLanguage(en: 'Decision Making Mastery'),
          ),
        ),
      );
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildPage(cubit));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboard_v2_primary_cta')), findsOneWidget);
    expect(find.byKey(const Key('onboard_v2_secondary_cta')), findsOneWidget);
    expect(find.text('Decision Making Mastery'), findsOneWidget);
  });

  testWidgets('fallback recommendation hides primary CTA and keeps secondary CTA', (tester) async {
    final cubit = _SeededOnboardV2Cubit()
      ..seed(
        const OnboardV2State(
          currentPage: OnboardV2PageStep.p7Recommendation,
          recommendationStatus: OnboardV2RecommendationStatus.fallback,
        ),
      );
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildPage(cubit));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboard_v2_primary_cta')), findsNothing);
    expect(find.byKey(const Key('onboard_v2_secondary_cta')), findsOneWidget);
    expect(find.text('Your course map is ready'), findsOneWidget);
  });
}

Widget _buildPage(OnboardV2Cubit cubit) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TranslationProvider(
      child: MaterialApp(
        home: BlocProvider<OnboardV2Cubit>.value(
          value: cubit,
          child: const OnboardV2RecommendationPage(),
        ),
      ),
    ),
  );
}
