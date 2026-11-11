import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';
import 'package:mockito/mockito.dart';

import '../../../../support/test_di.dart';

class _NoopTrackingService extends BaseTrackingService {}

class _CourseEntryAuthBloc extends Mock implements AuthBloc {
  _CourseEntryAuthBloc(this.result);

  final CourseEntryBootstrapResult result;
  int bootstrapCount = 0;

  @override
  AuthState get state => AuthState.initial();

  @override
  Stream<AuthState> get stream => const Stream.empty();

  @override
  bool get isClosed => false;

  @override
  Future<void> close() async {}

  @override
  Future<CourseEntryBootstrapResult> bootstrapCourseEntrySession() async {
    bootstrapCount += 1;
    return result;
  }
}

class _ReadyNotificationCubit extends NotificationCubit {
  @override
  Future<NotificationState> refreshPermissionState({
    bool syncAuthorizedPreference = false,
    bool syncPreferenceToPermissionState = false,
  }) async {
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
    final nextState = state.copyWith(
      hasLoadedPermissionState: true,
      isLoading: false,
      canRequestPermission: false,
      permissionStatus: NotificationPermissionStatus.authorized,
    );
    emit(nextState);
    return nextState;
  }

  @override
  Future<NotificationState> disableAppPreference() async {
    final nextState = state.copyWith(
      hasLoadedPermissionState: true,
      isLoading: false,
      canRequestPermission: true,
      permissionStatus: NotificationPermissionStatus.notDetermined,
    );
    emit(nextState);
    return nextState;
  }
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
    AppConfig.instance.rootNaviKey = GlobalKey<NavigatorState>();
    AppDI.injector.registerSingleton<ITrackingService>(AppTrackingService(_NoopTrackingService()));
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('notification request gate uses P6 body without step header', (tester) async {
    final notificationCubit = _ReadyNotificationCubit();
    final userCubit = UserCubit(_NoopTrackingService());
    addTearDown(notificationCubit.close);
    addTearDown(userCubit.close);

    await tester.pumpWidget(_buildPage(notificationCubit, userCubit));
    await tester.pump();

    expect(find.byType(OnboardV2ProgressHeader), findsNothing);
    expect(find.text('Keep your'), findsOneWidget);
    expect(find.text('momentum'), findsOneWidget);
    expect(find.text('Only helpful reminders, never spam'), findsOneWidget);
    expect(find.byKey(const Key('onboard_v2_notification_phone_preview')), findsOneWidget);
    expect(find.byKey(const Key('onboard_v2_notification_card')), findsOneWidget);
    expect(find.byKey(const Key('notification_request_primary_cta')), findsOneWidget);
    expect(find.byKey(const Key('notification_request_secondary_cta')), findsOneWidget);
  });

  testWidgets('course-entry notification request gate uses the same notification body before CTA', (tester) async {
    final notificationCubit = _ReadyNotificationCubit();
    final userCubit = UserCubit(_NoopTrackingService());
    addTearDown(notificationCubit.close);
    addTearDown(userCubit.close);

    await tester.pumpWidget(_buildPage(notificationCubit, userCubit, courseEntryMode: true));
    await tester.pump();

    expect(userCubit.state.hasCompletedCourseEntryNotificationGate, isFalse);
    expect(userCubit.state.hasPendingFirstTimePaywallAfterAuth, isFalse);
    expect(find.byType(OnboardV2ProgressHeader), findsNothing);
    expect(find.text('Keep your'), findsOneWidget);
    expect(find.text('momentum'), findsOneWidget);
    expect(find.byKey(const Key('notification_request_primary_cta')), findsOneWidget);
    expect(find.byKey(const Key('notification_request_secondary_cta')), findsOneWidget);
  });

  testWidgets('course-entry CTA success completes gate and routes to Course', (tester) async {
    final notificationCubit = _ReadyNotificationCubit();
    final userCubit = UserCubit(_NoopTrackingService());
    final authBloc = _CourseEntryAuthBloc(CourseEntryBootstrapResult.success);
    addTearDown(notificationCubit.close);
    addTearDown(userCubit.close);

    await tester.pumpWidget(_buildPage(notificationCubit, userCubit, authBloc: authBloc, courseEntryMode: true));
    await tester.pump();
    await tester.tap(find.byKey(const Key('notification_request_secondary_cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(userCubit.state.hasCompletedCourseEntryNotificationGate, isTrue);
    expect(userCubit.state.isUserPassOnboarding, isFalse);
    expect(find.text('course-route'), findsOneWidget);
    expect(authBloc.bootstrapCount, 1);
  });

  testWidgets('course-entry CTA retryable failure keeps the user on notification page', (tester) async {
    final notificationCubit = _ReadyNotificationCubit();
    final userCubit = UserCubit(_NoopTrackingService());
    final authBloc = _CourseEntryAuthBloc(CourseEntryBootstrapResult.retryableFailure);
    addTearDown(notificationCubit.close);
    addTearDown(userCubit.close);

    await tester.pumpWidget(_buildPage(notificationCubit, userCubit, authBloc: authBloc, courseEntryMode: true));
    await tester.pump();
    await tester.tap(find.byKey(const Key('notification_request_secondary_cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(userCubit.state.hasCompletedCourseEntryNotificationGate, isTrue);
    expect(find.byKey(const Key('notification_request_secondary_cta')), findsOneWidget);
    expect(find.text('course-route'), findsNothing);
    expect(find.text('register-route'), findsNothing);
    expect(authBloc.bootstrapCount, 1);
  });

  testWidgets('course-entry CTA unrecoverable failure routes to plain Register', (tester) async {
    final notificationCubit = _ReadyNotificationCubit();
    final userCubit = UserCubit(_NoopTrackingService());
    final authBloc = _CourseEntryAuthBloc(CourseEntryBootstrapResult.unrecoverableFailure);
    addTearDown(notificationCubit.close);
    addTearDown(userCubit.close);

    await tester.pumpWidget(_buildPage(notificationCubit, userCubit, authBloc: authBloc, courseEntryMode: true));
    await tester.pump();
    await tester.tap(find.byKey(const Key('notification_request_secondary_cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(userCubit.state.hasCompletedCourseEntryNotificationGate, isTrue);
    expect(find.text('register-route'), findsOneWidget);
    expect(authBloc.bootstrapCount, 1);
  });
}

Widget _buildPage(
  NotificationCubit notificationCubit,
  UserCubit userCubit, {
  AuthBloc? authBloc,
  bool courseEntryMode = false,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider<NotificationCubit>.value(value: notificationCubit),
            BlocProvider<UserCubit>.value(value: userCubit),
            BlocProvider<AuthBloc>.value(value: authBloc ?? _CourseEntryAuthBloc(CourseEntryBootstrapResult.retryableFailure)),
          ],
          child: NotificationRequestPage(courseEntryMode: courseEntryMode),
        ),
      ),
      GoRoute(
        path: RoutePath.course,
        builder: (context, state) => const Text('course-route'),
      ),
      GoRoute(
        path: RoutePath.register,
        builder: (context, state) => const Text('register-route'),
      ),
    ],
  );

  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TranslationProvider(
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}
