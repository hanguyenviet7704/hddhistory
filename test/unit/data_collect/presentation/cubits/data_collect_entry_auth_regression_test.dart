import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

class _FakeDeviceInfoService implements IDeviceInfoService {
  @override
  Future<String> get deviceName async => 'test-device';

  @override
  Future<BaseDeviceInfo?> get deviceInfo async => null;

  @override
  Future<String> get deviceToken async => 'test-device-token';

  @override
  Future<void> getAllDeviceInfo() async {}

  @override
  Future<int?> getAndroidSdkVersion() async => null;

  @override
  Future<bool> isAndroid13OrHigher() async => false;
}

class _FakeOnboardBranchingRepository implements IOnboardBranchingRepository {
  _FakeOnboardBranchingRepository(this._scenario);

  final OnboardingScenarioBranchingEntity _scenario;

  @override
  TaskEither<AppException, OnboardingScenarioBranchingEntity> getOnboardingScenarioBranching() {
    return TaskEither.right(_scenario);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AppDI.injector.reset();
    AppConfig.instance.rootNaviKey = GlobalKey<NavigatorState>();
    AppDI.injector.registerSingleton<ITrackingService>(AppTrackingService(NoOpTrackingService()));
  });

  tearDown(() async {
    if (AppDI.injector.isRegistered<DataCollectCubit>()) {
      await AppDI.injector.get<DataCollectCubit>().close();
    }
    await AppDI.injector.reset();
  });

  test('fallback from branching sets branching-skip and keeps anonymous-skip false when no silent login succeeded', () async {
    final dataCollectCubit = DataCollectCubit(_FakeDeviceInfoService());
    AppDI.injector.registerSingleton<DataCollectCubit>(dataCollectCubit);

    final cubit = OnboardBranchingCubit(
      GetOnboardingScenarioBranchingUseCase(
        _FakeOnboardBranchingRepository(
          const OnboardingScenarioBranchingEntity(
            entrySceneId: 'scene_1',
            scenes: [],
          ),
        ),
      ),
    );

    await cubit.loadOnboardingScenarioBranching();
    cubit.startScenario();

    expect(cubit.state.status, OnboardBranchingStatus.failure);
    expect(dataCollectCubit.state.shouldSkipBranchingFlow, isTrue);
    expect(dataCollectCubit.state.shouldSkipAnonymousLogin, isFalse);

    await cubit.close();
  });
}
