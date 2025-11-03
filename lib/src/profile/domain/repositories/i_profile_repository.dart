part of '../../profile.dart';

abstract class IProfileRepository {
  TaskEither<AppException, BasePageBreak<UserEntity>> getAllUsers(
    PageBreakRequest request,
  );
  TaskEither<AppException, UserEntity> getUser(String id);
  TaskEither<AppException, UserEntity> createUser(UserEntity entity);
  TaskEither<AppException, UserEntity> updateUser(UserEntity entity);
  TaskEither<AppException, Unit> deleteUser(String id);
}
