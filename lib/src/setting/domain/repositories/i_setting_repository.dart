part of '../../setting.dart';

abstract class ISettingRepository {
  TaskEither<AppException, SettingEntity> getSetting(String id);
  
}

