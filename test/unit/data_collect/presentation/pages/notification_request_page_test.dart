import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

class _NoopTrackingService extends BaseTrackingService {}

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
    LocaleSettings.setLocaleSync(AppLocale.en);
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
}

Widget _buildPage(NotificationCubit notificationCubit, UserCubit userCubit) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TranslationProvider(
      child: MaterialApp(
        navigatorKey: AppConfig.instance.rootNaviKey,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<NotificationCubit>.value(value: notificationCubit),
            BlocProvider<UserCubit>.value(value: userCubit),
          ],
          child: const NotificationRequestPage(),
        ),
      ),
    ),
  );
}
