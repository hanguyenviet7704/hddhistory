part of '../../setting.dart';

abstract interface class ISettingRepository {
  TaskEither<AppException, SettingEntity> getSetting(String id);
}

@LazySingleton(as: ISettingRepository)
class SettingRepository with RestfulRequestHandlerMixin implements ISettingRepository {

  SettingRepository();

  @override
  TaskEither<AppException, SettingEntity> getSetting(String id) {
    throw UnimplementedError();
  }
}
