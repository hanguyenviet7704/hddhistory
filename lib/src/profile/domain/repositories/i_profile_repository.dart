part of '../../profile.dart';

abstract class IProfileRepository {
  TaskEither<AppException, UserEntity> getUser(String id);
  TaskEither<AppException, UserEntity> updateUser(Map<String, dynamic> params);
}
