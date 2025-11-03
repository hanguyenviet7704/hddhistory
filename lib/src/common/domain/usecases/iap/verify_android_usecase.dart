part of '../usecases.dart';

class VerifyAndroidParams {
  final String receiptData;
  final String productId;

  VerifyAndroidParams({this.receiptData = '', this.productId = ''});
}

@lazySingleton
class VerifyAndroidUsecase implements UseCaseWithParams<VerifyAndroidParams, BaseResponse<IapVerify>> {
  final IIAPRepository _iapRepository;

  VerifyAndroidUsecase(this._iapRepository);

  @override
  TaskEither<AppException, BaseResponse<IapVerify>> call(VerifyAndroidParams params) => _iapRepository.verifyAndroidPurchase(params);
}
