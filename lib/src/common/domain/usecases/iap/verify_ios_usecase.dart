part of '../usecases.dart';

class VerifyIOSParams {
  final String receiptData;
  final String transactionId;
  final bool isSandbox;

  VerifyIOSParams({required this.receiptData, this.transactionId = '', this.isSandbox = false});
}

@lazySingleton
class VerifyIOSUsecase implements UseCaseWithParams<VerifyIOSParams, BaseResponse<IapVerify>> {
  final IIAPRepository _iapRepository;

  VerifyIOSUsecase(this._iapRepository);

  @override
  TaskEither<AppException, BaseResponse<IapVerify>> call(VerifyIOSParams params) => _iapRepository.verifyIOSPurchase(params);
}
