part of '../usecases.dart';

@lazySingleton
class RestoreUsecase implements UseCaseWithoutParams<BaseResponse<IapVerify>> {
  final IIAPRepository _iapRepository;

  RestoreUsecase(this._iapRepository);

  @override
  TaskEither<AppException, BaseResponse<IapVerify>> call()  => _iapRepository.restore();
}
