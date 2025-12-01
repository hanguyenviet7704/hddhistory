part of '../../monetization.dart';

class PurchaseParams {
  final String productId;
  final PurchaseType type;

  PurchaseParams({required this.productId, required this.type});
}

@lazySingleton
class PurchaseUsecase implements UseCaseWithParams<PurchaseParams, IapVerifyEntity> {
  final IMonetizationRepository _iapRepository;

  PurchaseUsecase(this._iapRepository);

  @override
  TaskEither<AppException, IapVerifyEntity> call(PurchaseParams params) => _iapRepository.purchase(params);
}
