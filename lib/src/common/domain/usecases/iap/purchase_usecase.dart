part of '../usecases.dart';

class PurchaseParams {
  final String productId;
  final PurchaseType type;

  PurchaseParams({required this.productId, required this.type});
}

@lazySingleton
class PurchaseUsecase implements UseCaseWithParams<PurchaseParams, BaseResponse<IapVerify>> {
  final IIAPRepository _iapRepository;

  PurchaseUsecase(this._iapRepository);

  @override
  TaskEither<AppException, BaseResponse<IapVerify>> call(PurchaseParams params) => _iapRepository.purchase(params);
}
