part of '../../monetization.dart';

class VerifyIOSParams {
  final String receiptData;
  final String transactionId;
  final bool isSandbox;

  VerifyIOSParams({required this.receiptData, this.transactionId = '', this.isSandbox = false});
}

@lazySingleton
class VerifyIOSUsecase implements UseCaseWithParams<VerifyIOSParams, IapVerifyEntity> {
  final IMonetizationRepository _iapRepository;

  VerifyIOSUsecase(this._iapRepository);

  @override
  TaskEither<AppException, IapVerifyEntity> call(VerifyIOSParams params) => _iapRepository.verifyIOSPurchase(params);
}
