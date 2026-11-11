part of '../../onboard.dart';

abstract class IOnboardRepository {
  TaskEither<AppException, OnboardEntity> getAllOnboards();
  TaskEither<AppException, UserEntity> getUserByDeviceId(String deviceId);
}
