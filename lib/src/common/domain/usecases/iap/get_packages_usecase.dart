part of '../usecases.dart';

@lazySingleton
class GetPackagesUsecase implements UseCaseWithoutParams<BaseResponseList<IapProduct>> {
  final IIAPRepository _iapRepository;

  GetPackagesUsecase(this._iapRepository);

  @override
  TaskEither<AppException, BaseResponseList<IapProduct>> call()  => _iapRepository.getProducts();
}
