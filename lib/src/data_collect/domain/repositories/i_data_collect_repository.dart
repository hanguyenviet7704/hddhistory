part of '../../data_collect.dart';

abstract class IDataCollectRepository {
  TaskEither<AppException, UserCollectDataEntity> getUserCollectData(String id);
  TaskEither<AppException, List<UserCollectDataEntity>> getAllUserCollectDatas();
  TaskEither<AppException, UserCollectDataEntity> createUserCollectData(UserCollectDataEntity entity);
  TaskEither<AppException, UserCollectDataEntity> updateUserCollectData(UserCollectDataEntity entity);
  TaskEither<AppException, Unit> deleteUserCollectData(String id);
}
