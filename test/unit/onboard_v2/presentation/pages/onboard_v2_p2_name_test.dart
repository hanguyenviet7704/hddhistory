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

class _FakeOnboardingRepository implements IOnboardingRepository {
  @override
  TaskEither<AppException, OnboardingContentConfigEntity> getOnboardingConfig() => TaskEither.right(const OnboardingContentConfigEntity());
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

  @override
  TaskEither<AppException, List<String>> getSearchHistory() => TaskEither.right(const []);

  @override
  TaskEither<AppException, Unit> saveSearchQuery(String query) => TaskEither.right(unit);

  @override
  TaskEither<AppException, Unit> clearSearchHistory() => TaskEither.right(unit);

  @override
  TaskEither<AppException, List<CourseEntity>> getRecentCourses() => TaskEither.right(const []);

  @override
  TaskEither<AppException, Unit> recordCourseView(String courseId) => TaskEither.right(unit);

  @override
  TaskEither<AppException, Unit> clearRecentCourses() => TaskEither.right(unit);
}

class _SeededOnboardV2Cubit extends OnboardV2Cubit {
  _SeededOnboardV2Cubit()
    : super.withRandom(
        GetOnboardingContentConfigUseCase(_FakeOnboardingRepository()),
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
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('P2 focuses name input and handles keyboard done action', (tester) async {
    final cubit = _SeededOnboardV2Cubit()..seed(const OnboardV2State(currentPage: OnboardV2PageStep.p2Name));
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildPage(cubit));
    await tester.pump();

    final waveHandImage = tester.widget<Image>(find.byKey(const Key('onboard_v2_name_wave_hand')));
    expect((waveHandImage.image as AssetImage).assetName, AppAsset.icons.app.icWaveHand.path);

    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.enterText(find.byKey(const Key('onboard_v2_name_input')), 'Alice');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(cubit.state.currentPage, OnboardV2PageStep.p3Age);
    expect(cubit.state.name, 'Alice');
    expect(editableText.focusNode.hasFocus, isFalse);
  });

  testWidgets('P2 CTA dismisses keyboard before continuing', (tester) async {
    final cubit = _SeededOnboardV2Cubit()..seed(const OnboardV2State(currentPage: OnboardV2PageStep.p2Name));
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildPage(cubit));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('onboard_v2_name_input')), 'Bob');
    await tester.pump();

    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('onboard_v2_primary_cta')));
    await tester.pump();

    expect(editableText.focusNode.hasFocus, isFalse);
    expect(cubit.state.currentPage, OnboardV2PageStep.p3Age);
    expect(cubit.state.name, 'Bob');
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
          child: const OnboardV2NamePage(),
        ),
      ),
    ),
  );
}
