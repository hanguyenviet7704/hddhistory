part of '../../monetization.dart';

class VerifyAndroidParams {
  final String receiptData;
  final String productId;

  VerifyAndroidParams({this.receiptData = '', this.productId = ''});
}

@lazySingleton
class VerifyAndroidUsecase implements UseCaseWithParams<VerifyAndroidParams, IapVerifyEntity> {
  final IMonetizationRepository _iapRepository;

  VerifyAndroidUsecase(this._iapRepository);

  @override
  TaskEither<AppException, IapVerifyEntity> call(VerifyAndroidParams params) => _iapRepository.verifyAndroidPurchase(params);
}
