part of '../../setting.dart';

@lazySingleton
class GetSettingUseCase implements UseCaseWithParams<String, SettingEntity> {
  final ISettingRepository _repository;

  GetSettingUseCase(this._repository);

  @override
  TaskEither<AppException, SettingEntity> call(String params) {
    return _repository.getSetting(params);
  }
}

