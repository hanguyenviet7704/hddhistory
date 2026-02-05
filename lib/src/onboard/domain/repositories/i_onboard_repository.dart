part of '../../onboard.dart';

abstract class IOnboardRepository {
  TaskEither<AppException, OnboardEntity> getAllOnboards();
}
