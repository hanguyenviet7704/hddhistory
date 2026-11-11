import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hddhistory/hddhistory.dart';

class _FakeDeviceInfoService implements IDeviceInfoService {
  String currentDeviceToken = 'device-123';

  @override
  Future<String> get deviceName async => 'test-device';

  @override
  Future<BaseDeviceInfo?> get deviceInfo async => null;

  @override
  Future<String> get deviceToken async => currentDeviceToken;

  @override
  Future<void> getAllDeviceInfo() async {}

  @override
  Future<int?> getAndroidSdkVersion() async => null;

  @override
  Future<bool> isAndroid13OrHigher() async => false;
}

class _FakeOnboardRepository implements IOnboardRepository {
  String? requestedDeviceId;
  TaskEither<AppException, UserEntity> userByDeviceResult = TaskEither.right(const UserEntity());

  @override
  TaskEither<AppException, OnboardEntity> getAllOnboards() => TaskEither.right(const OnboardEntity());

  @override
  TaskEither<AppException, UserEntity> getUserByDeviceId(String deviceId) {
    requestedDeviceId = deviceId;
    return userByDeviceResult;
  }
}

void main() {
  group('OnboardCubit.loadUserByDeviceId', () {
    late _FakeDeviceInfoService deviceInfoService;
    late _FakeOnboardRepository repository;
    late OnboardCubit cubit;

    setUp(() {
      deviceInfoService = _FakeDeviceInfoService();
      repository = _FakeOnboardRepository();
      cubit = OnboardCubit(
        GetAllOnboardsUseCase(repository),
        GetUserByDeviceIdUseCase(repository),
        deviceInfoService,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('marks device as recognized when server returns a user with id', () async {
      repository.userByDeviceResult = TaskEither.right(const UserEntity(id: 'user-1'));

      await cubit.loadUserByDeviceId();

      expect(repository.requestedDeviceId, 'device-123');
      expect(cubit.state.deviceCheckStatus, OnboardDeviceCheckStatus.success);
      expect(cubit.state.hasRecognizedDevice, isTrue);
      expect(cubit.state.shouldContinueOnboarding, isFalse);
      expect(cubit.state.userByDeviceId.id, 'user-1');
    });

    test('continues onboarding when device token is empty', () async {
      deviceInfoService.currentDeviceToken = '';

      await cubit.loadUserByDeviceId();

      expect(repository.requestedDeviceId, isNull);
      expect(cubit.state.deviceCheckStatus, OnboardDeviceCheckStatus.success);
      expect(cubit.state.hasRecognizedDevice, isFalse);
      expect(cubit.state.shouldContinueOnboarding, isTrue);
    });

    test('treats not found as a safe onboarding continuation', () async {
      repository.userByDeviceResult = TaskEither.left(const AppException.notFound('missing'));

      await cubit.loadUserByDeviceId();

      expect(cubit.state.deviceCheckStatus, OnboardDeviceCheckStatus.success);
      expect(cubit.state.hasRecognizedDevice, isFalse);
      expect(cubit.state.shouldContinueOnboarding, isTrue);
      expect(cubit.state.deviceCheckErrorMessage, isNull);
    });

    test('stores failure details for unexpected lookup errors', () async {
      repository.userByDeviceResult = TaskEither.left(const AppException.server('boom'));

      await cubit.loadUserByDeviceId();

      expect(cubit.state.deviceCheckStatus, OnboardDeviceCheckStatus.failure);
      expect(cubit.state.hasRecognizedDevice, isFalse);
      expect(cubit.state.shouldContinueOnboarding, isTrue);
      expect(cubit.state.deviceCheckErrorMessage, 'boom');
    });
  });
}
