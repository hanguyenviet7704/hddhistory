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
  TaskEither<AppException, CourseEntity> getCourse(String id) => TaskEither.left(const AppException.notFound('missing course'));

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

class _GateNotificationCubit extends NotificationCubit {
  _GateNotificationCubit({required this.refreshCompleter});

  final Completer<void> refreshCompleter;
  int enableCount = 0;

  @override
  Future<NotificationState> refreshPermissionState({
    bool syncAuthorizedPreference = false,
    bool syncPreferenceToPermissionState = false,
  }) async {
    emit(state.copyWith(isLoading: true));
    await refreshCompleter.future;
    final nextState = state.copyWith(
      hasLoadedPermissionState: true,
      isLoading: false,
      canRequestPermission: true,
      permissionStatus: NotificationPermissionStatus.notDetermined,
    );
    emit(nextState);
    return nextState;
  }

  @override
  Future<NotificationState> enableFromOnboardingGate() async {
    enableCount += 1;
    final nextState = state.copyWith(
      hasLoadedPermissionState: true,
      isLoading: false,
      canRequestPermission: false,
      permissionStatus: NotificationPermissionStatus.authorized,
    );
    emit(nextState);
    return nextState;
  }
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('P6 renders Figma-aligned notification preview', (tester) async {
    final refreshCompleter = Completer<void>();
    addTearDown(() {
      if (!refreshCompleter.isCompleted) refreshCompleter.complete();
    });
    final notificationCubit = _GateNotificationCubit(refreshCompleter: refreshCompleter);
    final onboardCubit = _SeededOnboardV2Cubit()..seed(const OnboardV2State(currentPage: OnboardV2PageStep.p6Notification));
    final userCubit = UserCubit(_NoopTrackingService());
    addTearDown(notificationCubit.close);
    addTearDown(onboardCubit.close);
    addTearDown(userCubit.close);

    await tester.pumpWidget(_buildPage(onboardCubit, notificationCubit, userCubit));

    expect(find.text('Keep your'), findsOneWidget);
    expect(find.text('momentum'), findsOneWidget);
    expect(find.textContaining('Time to focus'), findsOneWidget);
    expect(find.byKey(const Key('onboard_v2_notification_phone_preview')), findsOneWidget);
    expect(find.byKey(const Key('onboard_v2_notification_card')), findsOneWidget);

    refreshCompleter.complete();
    await tester.pump();
  });

  testWidgets('notification preview card enters then floats with synchronized shadow', (tester) async {
    final refreshCompleter = Completer<void>();
    addTearDown(() {
      if (!refreshCompleter.isCompleted) refreshCompleter.complete();
    });
    final notificationCubit = _GateNotificationCubit(refreshCompleter: refreshCompleter);
    final onboardCubit = _SeededOnboardV2Cubit()..seed(const OnboardV2State(currentPage: OnboardV2PageStep.p6Notification));
    final userCubit = UserCubit(_NoopTrackingService());
    addTearDown(notificationCubit.close);
    addTearDown(onboardCubit.close);
    addTearDown(userCubit.close);

    await tester.pumpWidget(_buildPage(onboardCubit, notificationCubit, userCubit));

    final entryY = _notificationCardDy(tester);
    final restingShadow = _notificationCardShadow(tester);
    expect(entryY, lessThan(-20));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 640));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 800));

    final liftedY = _notificationCardDy(tester);
    final liftedShadow = _notificationCardShadow(tester);
    expect(liftedY, lessThan(0));
    expect(liftedShadow.blurRadius, greaterThan(restingShadow.blurRadius));
    expect(liftedShadow.offset.dy, greaterThan(restingShadow.offset.dy));

    await tester.pump(const Duration(milliseconds: 1600));

    final sunkenY = _notificationCardDy(tester);
    final sunkenShadow = _notificationCardShadow(tester);
    expect(sunkenY, greaterThan(0));
    expect(sunkenShadow.blurRadius, lessThan(liftedShadow.blurRadius));
    expect(sunkenShadow.offset.dy, lessThan(liftedShadow.offset.dy));

    refreshCompleter.complete();
    await tester.pump();
  });

  testWidgets('Notify me waits for initial permission refresh before requesting permission', (tester) async {
    final refreshCompleter = Completer<void>();
    addTearDown(() {
      if (!refreshCompleter.isCompleted) refreshCompleter.complete();
    });
    final notificationCubit = _GateNotificationCubit(refreshCompleter: refreshCompleter);
    final onboardCubit = _SeededOnboardV2Cubit()..seed(const OnboardV2State(currentPage: OnboardV2PageStep.p6Notification));
    final userCubit = UserCubit(_NoopTrackingService());
    addTearDown(notificationCubit.close);
    addTearDown(onboardCubit.close);
    addTearDown(userCubit.close);

    await tester.pumpWidget(_buildPage(onboardCubit, notificationCubit, userCubit));
    await tester.tap(find.byKey(const Key('onboard_v2_primary_cta')));
    await tester.pump();

    expect(notificationCubit.enableCount, 0);
    expect(onboardCubit.state.currentPage, OnboardV2PageStep.p6Notification);

    refreshCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(notificationCubit.enableCount, 1);
    expect(onboardCubit.state.currentPage, OnboardV2PageStep.p7Recommendation);
  });
}

Widget _buildPage(
  OnboardV2Cubit onboardCubit,
  NotificationCubit notificationCubit,
  UserCubit userCubit,
) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TranslationProvider(
      child: MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<OnboardV2Cubit>.value(value: onboardCubit),
            BlocProvider<NotificationCubit>.value(value: notificationCubit),
            BlocProvider<UserCubit>.value(value: userCubit),
          ],
          child: const OnboardV2NotificationPage(),
        ),
      ),
    ),
  );
}

double _notificationCardDy(WidgetTester tester) {
  final transform = tester.widget<Transform>(find.byKey(const Key('onboard_v2_notification_card_transform')));
  return transform.transform.getTranslation().y;
}

BoxShadow _notificationCardShadow(WidgetTester tester) {
  final container = tester.widget<Container>(find.byKey(const Key('onboard_v2_notification_card')));
  final decoration = container.decoration! as BoxDecoration;
  return decoration.boxShadow!.single;
}
